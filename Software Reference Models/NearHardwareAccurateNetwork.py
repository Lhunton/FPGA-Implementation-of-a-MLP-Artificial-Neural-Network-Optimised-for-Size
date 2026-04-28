# 
# Lewis Hunton | 11135261 | 07/10/25 | Electronics Engineering 3rd Year Project
# Neural Network for the identification of hand written 8x8 resolution numbers for results verification of VLSI hardware 
#
import torch
import torch.nn as nn
import torch.optim as optim
import torch.nn.functional as F
from torch.utils.data import DataLoader, TensorDataset
import numpy as np
import matplotlib.pyplot as plt
from sklearn.datasets import load_digits
from sklearn.model_selection import train_test_split
import math
import json
import seaborn as sns
import pandas as pd

torch.manual_seed(777)

#Constant definitions
inputNodes = 64
hiddenNodes = 64
outputNodes = 10

learningRate = 0.14
alpha = 1
batchSize = 32
epochs = 50
#bitResolutions = [16,14,12,10,8,6]
bitResolutions = [8]
bitResolution = 16
quantise = True

#HiddenNodeCount = [16, 32, 64, 96, 128]
HiddenNodeCount = [16]

QBits = 7
QScale = 1 << QBits #128
QMax = 127
QMin = -128

digits = load_digits()

#Function definitions
#activation functions
activationFunctions = {
    'ELU': (lambda x: torch.where(x > 0, x, alpha * torch.exp(x) - 1),
            lambda x: torch.where(x > 0, torch.ones_like(x), alpha * torch.exp(x))),

    'ReLu': (lambda x: torch.maximum(torch.zeros_like(x), x),
             lambda x: torch.where(x > 0, torch.ones_like(x), torch.zeros_like(x))),

    'Sigmoid': (lambda x: (1/(1+torch.exp(-x))),
                lambda x: (1/(1+torch.exp(-x))) * (1 - (1/(1+torch.exp(-x))))),
    }

def normalise(x):
    return x/16.0

def startTraining(HiddenSize):
    hiddenNodesWeights = torch.rand(inputNodes, HiddenSize) * math.sqrt(2/inputNodes)
    outputNodesWeights = torch.rand(HiddenSize,outputNodes) * math.sqrt(2/HiddenSize)
    hiddenNodesBias = torch.zeros(HiddenSize)
    outputNodesBias = torch.zeros(outputNodes)
    return hiddenNodesWeights,outputNodesWeights,hiddenNodesBias,outputNodesBias

def Q07Quantisation(values):
    Q = torch.round(values * QScale)
    Q = torch.clamp(Q, QMin, QMax)
    return Q.to(torch.int8)

def Q07Requantisation(R, Shift):
    R = R >> Shift
    R = torch.clamp(R, QMin, QMax)
    return R.to(torch.int8)

def Q07Matmul(X, Y):
    return torch.matmul(X.int(), Y.int())

def Q07RescaleClamp(acc, shift):
    acc = acc >> shift
    acc = torch.clamp(acc, QMin, QMax)
    return acc.to(torch.int8)

def Q07ReLU(X):
    return torch.maximum(X, torch.zeros_like(X))

def Q07Forward(InputsQ, HiddenWQ, OutputWQ, HiddenBQ, OutputBQ, HiddenShift, OutputShift):
    h = Q07Matmul(InputsQ, HiddenWQ)
    
    h += HiddenBQ.int()
    h = Q07Requantisation(h, HiddenShift)

    h = torch.clamp(h, QMin, QMax)
    h = Q07ReLU(h)

    o = Q07Matmul(h, OutputWQ)
    
    o += OutputBQ.int()
    o = Q07Requantisation(o, OutputShift)

    o = torch.clamp(o, QMin, QMax)


    return o

def Q07Evaluation(loader, HiddenWQ, OutputWQ, HiddenBQ, OutputBQ, HiddenShift, OutputShift):
    Correct = 0
    Total = 0

    for data, targets in loader:
        InputsQ = Q07Quantisation(data)
        outputsQ = Q07Forward(InputsQ, HiddenWQ, OutputWQ, HiddenBQ, OutputBQ, HiddenShift, OutputShift)
        Predictions = torch.argmax(outputsQ, dim=1)

        Correct += (Predictions == targets).sum().item()
        Total += targets.size(0)


    accuracy = Correct / Total
    print("Q0.7 accuracy:", accuracy)
    return float(accuracy)


#Data processing definitions
def dataPreprocessing(x,y):
    normalisedX = normalise(x)

    tempTensorx = torch.FloatTensor(normalisedX)
    tempTensory = torch.LongTensor(y)

    return tempTensorx, tempTensory

def dataloading(trainX, trainY, testX, testY):
    #convert tensors into pairs of input + output tensors
    trainingDataset = TensorDataset(trainX, trainY)
    testingDataset = TensorDataset(testX,testY)

    #convert individual data tensors into a larger dataset (loaders)
    trainingLoader = DataLoader(trainingDataset, batch_size=batchSize, shuffle=True)
    testingLoader = DataLoader(testingDataset, batch_size=batchSize, shuffle=False)

    return trainingLoader, testingLoader

#Forward propagation definitions
def forwardPropagation(inputs, hiddenWeights, outputWeights, hiddenBias, outputBias, activationName, bits):
    if bits<16:
        inputs = quantisation(inputs, bits)

    #matrix multiplication of hidden layer
    #hiddenInputs = torch.matmul(inputs, hiddenWeights) + hiddenBias
    hiddenInputs = quantisedMatmul(inputs, hiddenWeights, bits)
    hiddenInputs = quantisedAdd(hiddenInputs, hiddenBias, bits)

    #Activation function applications
    tempActivationFunction, tempDerivativeFunction = activationFunctions[activationName]
    #hiddenOutputs = tempActivationFunction(hiddenInputs)
    hiddenOutputs = quantisedActivation(tempActivationFunction, hiddenInputs, bits)

    #matrix multiplication of output layer
    #outputInputs = torch.matmul(hiddenOutputs, outputWeights) + outputBias
    outputInputs = quantisedMatmul(hiddenOutputs, outputWeights, bits)
    outputInputs = quantisedAdd(outputInputs, outputBias, bits)

    return outputInputs, hiddenOutputs

#Training loop definitions
def trainingLoop(loader, hiddenWeights, outputWeights, hiddenBias, outputBias, learningRate, activationName, bits):
    losses = []
    accuracies = []

    #an epoch is 1 complete pass of data
    for epoch in range(epochs):
        totalLoss = 0
        correctPredictions = 0
        totalSamples = 0   

        #Loop through batches with forward pass
        for batchIdx, (data, targets) in enumerate(loader):
            #Forward pass
            outputs, hiddenActivations = forwardPropagation(data, hiddenWeights, outputWeights, hiddenBias, outputBias, activationName, bits)
            
            #loss calcs
            batchLoss = loss(outputs, targets)
            totalLoss += batchLoss.item()

            #Calculate accuracy for this batch
            predictions = torch.argmax(outputs, dim=1)
            correctPredictions += (predictions == targets).sum().item()
            totalSamples += targets.size(0)

            #backward pass
            hiddenWeightsGradient, outputWeightsGradient, hiddenBiasGradient, outputBiasGradient = backwardsPropagation(data, hiddenActivations, outputs, targets, hiddenWeights, outputWeights, hiddenBias, outputBias, activationName, bits)

            # Update weights
            hiddenWeights, outputWeights, hiddenBias, outputBias = updateWeights(hiddenWeights, outputWeights, hiddenBias, outputBias,hiddenWeightsGradient, outputWeightsGradient,hiddenBiasGradient, outputBiasGradient, bits)
        
        # Epoch statistics
        avgLoss = totalLoss / len(loader)
        accuracy = correctPredictions / totalSamples
        losses.append(avgLoss)
        accuracies.append(accuracy)
            
        print(f'Epoch {epoch+1}/{epochs}, Loss: {avgLoss:.4f}, Accuracy: {accuracy:.4f}')

    return hiddenWeights, outputWeights, hiddenBias, outputBias, losses, accuracies


#Loss calculations
def loss(outputs, targets):
        return F.cross_entropy(outputs, targets)

#Backward propagation definitions (WHY IS THIS SO HARD?? MAYBE BCS I CANT ACTUALLY READ THE TENSORS?!?!!)
def backwardsPropagation(inputs, hiddenOutputs, outputs, targets, hiddenWeights, outputWeights, hiddenBias, outputBias, activationName, bits):
    #Converts output values into a normalised so the sum of the values = 1
    targetSoftmax = F.softmax(outputs, dim=1)
    
    #creates array full of 0's and 1 where the largest value is (this is the systems answer)
    targetOnehot = F.one_hot(targets, num_classes=outputNodes)

    
    outputError = (targetSoftmax - targetOnehot.float()) / batchSize                                    #dLoss/dOutputs (how wrong the answer is)

    if bits<16:
        outputError = quantisation(outputError, bits)

    #Gradients calculation (how much the weight and bias are wrong and need to be adjusted by)
    #outputWeightsGradient = torch.matmul(hiddenOutputs.t(), outputError)                                #dLoss/dWeightOutputs (how much of the wrongness is from weight)
    outputWeightsGradient = quantisedMatmul(hiddenOutputs.t(), outputError, bits)
    #outputBiasGradient = torch.sum(outputError, dim=0)                                                  #dLoss/dBiasOutputs (how much of the wrongness is from bias)
    outputBiasGradient = quantisation(torch.sum(outputError, dim=0), bits)

    #chain rule to bring error in output layer back to hidden layer
    #hiddenError = torch.matmul(outputError, outputWeights.t())                                          #dLoss/dOutputs * dOutputs/dHiddenOutputs (moves error to hidden layer)
    hiddenError = quantisedMatmul(outputError, outputWeights.t(), bits)

    #Now apply ELU derivative
    #hiddenInputs = torch.matmul(inputs, hiddenWeights) + hiddenBias                                     #dLoss/dHiddenOutputs * dHiddenOutputs/dHiddenInputs
    hiddenInputs = quantisedMatmul(inputs, hiddenWeights, bits)
    hiddenInputs = quantisedAdd(hiddenInputs, hiddenBias, bits)

    tempActivationFunction, tempDerivativeFunction = activationFunctions[activationName]
    #hiddenError *= tempDerivativeFunction(hiddenInputs)                                                          #Reverse ELU 
    activationDerivative = tempDerivativeFunction(hiddenInputs)
    if bits<16:
        activationDerivative = quantisation(activationDerivative, bits)

    hiddenError = activationDerivative * hiddenError
    if bits<16:
        hiddenError = quantisation(hiddenError, bits)

    #hiddenWeightsGradient = torch.matmul(inputs.t(), hiddenError)                                       #dLoss/dWeightHidden (how much of the wrongness is from Weight)
    hiddenWeightsGradient = quantisedMatmul(inputs.t(), hiddenError, bits)
    #hiddenBiasGradient = torch.sum(hiddenError, dim=0)                                                  #dLoss/dBiasHidden (how much of the wrongness is from bias)
    hiddenBiasGradient = quantisation(torch.sum(hiddenError, dim=0), bits)

    return hiddenWeightsGradient, outputWeightsGradient, hiddenBiasGradient, outputBiasGradient

#updates weight function to apply gradients to current loops weights and biases
def updateWeights(hiddenWeights, outputWeights, hiddenBias, outputBias, hiddenWeightGradient, outputWeightsGradient, hiddenBiasGradient, outputBiasGradient, bits):
    hiddenWeights -= quantisation(learningRate * hiddenWeightGradient, bits)
    outputWeights -= quantisation(learningRate * outputWeightsGradient, bits)
    hiddenBias -= quantisation(learningRate * hiddenBiasGradient, bits)
    outputBias -= quantisation(learningRate * outputBiasGradient, bits)

    if bits < 16:
        hiddenWeights = quantisation(hiddenWeights, bits)
        outputWeights = quantisation(outputWeights, bits)
        hiddenBias = quantisation(hiddenBias, bits)
        outputBias = quantisation(outputBias, bits)

    return hiddenWeights, outputWeights, hiddenBias, outputBias

#Function def for data analysis
def evaluateModel(loader, hiddenWeights, outputWeights, hiddenBias, outputBias, activationName, bits):
    correctPredictions = 0
    totalPredictions = 0

    for data, targets in loader:
        outputs, _ = forwardPropagation(data, hiddenWeights, outputWeights, hiddenBias, outputBias, activationName, bits)
        predictions = torch.argmax(outputs, dim=1)
        correctPredictions += (predictions == targets).sum().item()
        totalPredictions += targets.size(0)

    accuracy = correctPredictions/totalPredictions
    print(f'Test accuracy: {accuracy:.20f}')
    return accuracy

def plotResults(allResults):
    plt.figure(figsize=(15,9))

    #figure 1: training loss
    activationColours = {'ELU': 'red', 'ReLu': 'green', 'Sigmoid': 'blue'}

    for i, activation in enumerate(['ELU', 'ReLu', 'Sigmoid'], 1):
        plt.subplot(3,3,i)
        plt.title(f'{activation} Training Loss at Varying Resolution')
        plt.xlabel('Epoch')
        plt.ylabel('Loss')
        plt.grid(True)
        for numHiddenNodes in HiddenNodeCount:
            for bits in bitResolutions:
                if bits in allResults[activation][numHiddenNodes]:
                    losses = allResults[activation][numHiddenNodes][bits]['losses']
                    plt.plot(losses, label=f'{numHiddenNodes} nodes, {bits} bits', 
                            linewidth=1, alpha=0.7)

    #figure 2: training accuracy
    for i, activation in enumerate(['ELU', 'ReLu', 'Sigmoid'], 4):
        plt.subplot(3,3,i)
        plt.title(f'{activation} Training Accuracy at Varying Resolution')
        plt.xlabel('Epoch')
        plt.ylabel('Accuracy')
        plt.grid(True)
        for numHiddenNodes in HiddenNodeCount:
            for bits in bitResolutions:
                if bits in allResults[activation][numHiddenNodes]:
                    accuracies = allResults[activation][numHiddenNodes][bits]['accuracies']
                    plt.plot(accuracies, label=f'{numHiddenNodes} nodes, {bits} bits', 
                            linewidth=1, alpha=0.7)

    for i, activation in enumerate(['ELU', 'ReLu', 'Sigmoid'], 7):
            bitData = []
            testAccuracyData = []

            plt.subplot(3,3,i)
            plt.title(f'{activation} Test Accuracy at Varying Resolution')
            plt.xlabel('Bit Resolution')
            plt.ylabel('Test Accuracy')
            plt.grid(True)
            accuracyMatrix = []
            for nodes in HiddenNodeCount:
                row = []
                for bits in bitResolutions:
                    accuracy = allResults[activation][nodes][bits]['testAccuracies']
                    row.append(accuracy)

                accuracyMatrix.append(row)
            
            df = pd.DataFrame(accuracyMatrix, 
                            index=HiddenNodeCount, 
                            columns=bitResolutions)
            
            df = df[sorted(df.columns, reverse=True)]
            df = df.astype(float)
            
            sns.heatmap(df, annot=True, fmt='.3f', cmap='viridis',
                    cbar_kws={'label': 'Test Accuracy'})
            plt.title(f'{activation} Accuracy Heatmap')
            plt.xlabel('Bit Resolution')
            plt.ylabel('Hidden Nodes')
            plt.yticks(rotation=0)

    plt.tight_layout(pad=1.0, h_pad=0.01, w_pad=1.0)

    plt.savefig("full_figure.png", dpi=600, bbox_inches='tight')

    plt.show()


def plotShiftHeatmap(shiftAccuracyMatrix, hidden_shifts, output_shifts,
                     bestHiddenShift, bestOutputShift,
                     title="Shift Calibration Heatmap"):

    df = pd.DataFrame(
        shiftAccuracyMatrix,
        index=hidden_shifts,
        columns=output_shifts
    )

    plt.figure(figsize=(10, 8))
    sns.heatmap(
        df,
        annot=True,
        fmt=".3f",
        cmap="viridis",
        cbar_kws={'label': 'Accuracy'}
    )

    plt.xlabel("Output Shift")
    plt.ylabel("Hidden Shift")
    plt.title(title)

    # Highlight best shift combination
    i = hidden_shifts.index(bestHiddenShift)
    j = output_shifts.index(bestOutputShift)



    plt.legend(loc="upper right")

    plt.savefig(f"{title.replace(' ', '_')}.png", dpi=600, bbox_inches='tight')
    
    plt.show()


def exportWeights(hiddenWeight, outputWeights, hiddenBias, outputBias, activationName, testAccuracy, bits, HiddenShift, OutputShift, filenamePrefix=""):
    
    
    NumInputNodes     = hiddenWeight.shape[0]
    NumHiddenNodes    = hiddenWeight.shape[1]
    NumOutputNodes    = outputWeights.shape[1]

    weights = {
        'format': 'Q0.7',
        'scale': 128,
        'HiddenShift': HiddenShift,
        'OutputShift': OutputShift,
        'hiddenWeights': hiddenWeight.tolist(),
        'outputWeights': outputWeights.tolist(),
        'hiddenBias': hiddenBias.tolist(),
        'outputBias': outputBias.tolist(),
    }

    filename = f"{filenamePrefix}NN_Hardware_{NumHiddenNodes}hidden_{bits}bit_{activationName}H_{HiddenShift}O_{OutputShift}.json"

    
    with open(filename, "w") as f:
        json.dump(weights, f, indent=2)


    print(f"Weights Exported {filename}")


#Quantisation functions
def quantisation(values, bits):
    if bits > 16:
        return values
    
    maxVal = torch.max(torch.abs(values))
    if maxVal == 0:
        return values
    
    scaleFactor = (2**(bits-1)-1) / maxVal

    intermediateQuantisation = torch.round(values * scaleFactor)
    quantisedVals = intermediateQuantisation / scaleFactor

    return quantisedVals

def quantisedMatmul(X, Y, bits):
    ans = torch.matmul(X, Y)
    return quantisation(ans, bits)

def quantisedAdd(X, Y, bits):
    ans = X + Y
    return quantisation(ans, bits)

def quantisedActivation(function, X, bits):
    ans = function(X)
    return quantisation(ans, bits)

#Main
def main():
    # Access the data and labels
    x = digits.data
    y = digits.target

    results = {}

    bestAcc = 0.0
    bestHiddenShift = None
    bestOutputShift = None

    hidden_shifts = list(range(2, 18))
    output_shifts = list(range(2, 18))

    #Function for splitting data set up and holding some data points in reserve for data validation  and credibility during report writing
    trainX, testX, trainY, testY = train_test_split(x, y, test_size=0.2, random_state=1, stratify=y)

    trainingTensorsx, trainingTensorsy = dataPreprocessing(trainX, trainY)
    testingTensorsx, testingTensorsy = dataPreprocessing(testX, testY)

    for activationName in ['ELU', 'ReLu', 'Sigmoid']:
        print(f"\n============================================================")
        print(f"Training with {activationName} activation function")
        print(f"============================================================")

        results[activationName] = {}
        for numHiddenNodes in HiddenNodeCount:
            print(f"Testing {numHiddenNodes} Hidden layer nodes")

            results[activationName][numHiddenNodes] = {}
            shiftAccuracyMatrix = np.zeros((len(hidden_shifts), len(output_shifts)))

            #hiddenNodes = numHiddenNodes

            for bits in bitResolutions:
                print(f"Testing {bits} bits of resolution")

                #bitResolution = bits
            
                trainingLoader, testLoader = dataloading(trainingTensorsx, trainingTensorsy, testingTensorsx, testingTensorsy)

                hiddenWeights, outputWeights, hiddenBias, outputBias = startTraining(numHiddenNodes)

                hiddenWeights, outputWeights, hiddenBias, outputBias, losses, accuracies = trainingLoop(trainingLoader, hiddenWeights, outputWeights, hiddenBias, outputBias, learningRate, activationName, bits)

                if quantise:
                    hiddenWeights = Q07Quantisation(hiddenWeights)
                    outputWeights = Q07Quantisation(outputWeights)
                    hiddenBias = Q07Quantisation(hiddenBias)
                    outputBias = Q07Quantisation(outputBias)

                    for i, HiddenShift in enumerate(hidden_shifts):
                        for j, OutputShift in enumerate(output_shifts):
                            testAccuracies = Q07Evaluation(testLoader, hiddenWeights, outputWeights, hiddenBias, outputBias, HiddenShift, OutputShift)

                            print(f"HiddenShift={HiddenShift}, OutputShift={OutputShift}, Acc={testAccuracies:.4f}")

                            shiftAccuracyMatrix[i, j] = testAccuracies

                            if testAccuracies > bestAcc:
                                bestAcc = testAccuracies
                                bestHiddenShift = HiddenShift
                                bestOutputShift = OutputShift

                            exportWeights(hiddenWeights, outputWeights, hiddenBias, outputBias, activationName, testAccuracies, bits, HiddenShift, OutputShift)

                    #analyseTestSet(testLoader, hiddenWeights, outputWeights, hiddenBias, outputBias, activationName, bits)

                    results[activationName][numHiddenNodes][bits] = {
                        'losses': losses,
                        'accuracies': accuracies,
                        'testAccuracies': testAccuracies,
                        'HiddenShift': bestHiddenShift,
                        'OutputShift': bestOutputShift
                    }

                
                print("BEST FIXED-POINT CONFIG:")
                print(f"HiddenShift = {bestHiddenShift}")
                print(f"OutputShift = {bestOutputShift}")
                print(f"Accuracy    = {bestAcc:.4f}")
                
                hidden_shifts = list(hidden_shifts)
                output_shifts = list(output_shifts)

                plotShiftHeatmap(
                    shiftAccuracyMatrix,
                    hidden_shifts,
                    output_shifts,
                    bestHiddenShift,
                    bestOutputShift,
                    title=f"{activationName} – {numHiddenNodes} Hidden Nodes – Q0.7"
                )



    plotResults(results)

if __name__ == "__main__":
    main()