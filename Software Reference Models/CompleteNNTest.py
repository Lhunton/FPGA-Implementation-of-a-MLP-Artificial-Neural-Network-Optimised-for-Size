import ok
import time
import numpy as np
from sklearn import datasets
import matplotlib.pyplot as plt
from sklearn.metrics import confusion_matrix
import seaborn as sns


class NeuralNetworkFPGA:
    def __init__(self, BITFILE):
        self.dev = ok.okCFrontPanel()

        print("Opening FPGA...")
        if self.dev.OpenBySerial("") != ok.okCFrontPanel.NoError:
            raise RuntimeError("ERROR: Couldn't open XEM3010")

        print("Loading bitfile:", BITFILE)
        if self.dev.ConfigureFPGA(BITFILE) != ok.okCFrontPanel.NoError:
            raise RuntimeError("ERROR: Couldn't load bitfile")

        self.dev.UpdateWireIns()
        self.dev.UpdateWireOuts()
        self.dev.UpdateTriggerOuts()

        # Endpoint mapping
        self.EP_INPUT  = 0x00     # WriteValid + WriteData wirein
        self.EP_TRIG   = 0x40     # Reset + Commit triggerin
        self.EP_CLASS  = 0x20     # Classification wireout
        self.EP_VALID  = 0x21     # ClassificationValid wireout
        self.EP_DONE_WO = 0x22    # DONE wireout endpoint (bit 0)

        print("FPGA ready.\n")


    def Reset(self):
        print("Resetting FPGA...")
        self.dev.UpdateTriggerOuts()
        self.dev.ActivateTriggerIn(self.EP_TRIG, 0)   # TriggerIn bit0 = Reset
        time.sleep(0.01)

    def SendPixel(self, value):
        self.dev.SetWireInValue(self.EP_INPUT, (value << 4) | 1)
        self.dev.UpdateWireIns()

        while True:
            self.dev.UpdateWireOuts()
            ready = self.dev.GetWireOutValue(0x23) & 1
            if ready:
                break

        self.dev.SetWireInValue(self.EP_INPUT, 0)
        self.dev.UpdateWireIns()

    def Commit(self):
        self.dev.UpdateTriggerOuts()
        self.dev.ActivateTriggerIn(self.EP_TRIG, 1)   # commit
        time.sleep(0.005)

    def WaitForDone(self, timeout_sec=1.0):
        t0 = time.time()
        while time.time() - t0 < timeout_sec:
            self.dev.UpdateWireOuts()

            done = self.dev.GetWireOutValue(self.EP_DONE_WO) & 0x1
            if done == 1:
                return True

        return False


    def GetResult(self):
        self.dev.UpdateWireOuts()
        cls   = self.dev.GetWireOutValue(self.EP_CLASS) & 0xF
        valid = self.dev.GetWireOutValue(self.EP_VALID) & 1
        return cls, valid



class NNTester:
    def __init__(self, fpga):
        self.fpga = fpga

    def PrepareImage(self, image):
        flat = image.flatten()
        flat = np.clip(flat, 0, 15).astype(int)
        return flat.tolist()

    def RunImage(self, pixels):
        assert len(pixels) == 64

        self.fpga.Reset()

        for p in pixels:
            self.fpga.SendPixel(p)

        self.fpga.Commit()

        if not self.fpga.WaitForDone():
            print("Timeout waiting for FPGA DONE")
            return None

        cls, valid = self.fpga.GetResult()
        if not valid:
            print("FPGA returned invalid result")
            return None

        return cls
    

def RunZeroInputTest(bitfile="NNToplevelPorts.bit"):
    """Send 64 zeros to the FPGA and return its classification output."""
    fpga = NeuralNetworkFPGA(bitfile)
    tester = NNTester(fpga)

    # 64 zero pixels
    zero_image = [0] * 64

    print("\nRunning Zero-Input Test (all pixels = 0)...\n")

    pred = tester.RunImage(zero_image)

    if pred is None:
        print("FPGA returned no valid classification.")
    else:
        print(f"FPGA classification output for zero-input image: {pred}")

    return pred

def RunFullTest(bitfile="NNToplevelPorts.bit", limit=None, plot=True):
    fpga   = NeuralNetworkFPGA(bitfile)
    tester = NNTester(fpga)

    digits = datasets.load_digits()
    images = digits.images
    labels = digits.target

    N = len(images) if limit is None else limit

    correct = 0
    preidctions = []
    truths = []

    print("\nStarting Full Digits Test\n")

    for i in range(N):
        img  = tester.PrepareImage(images[i])
        pred = tester.RunImage(img)
        truth = labels[i]

        preidctions.append(pred)
        truths.append(truth)

        print(f"Sample {i}: Predicted = {pred}, Truth = {truth}")

        if pred == truth:
            correct += 1

    accuracy = 100 * correct / N
    print(f"\nTest complete. Accuracy: {accuracy:.2f}% ({correct}/{N})")

    if plot:
        PlotResults(preidctions, truths)
        PlotConfusionMatrix(preidctions, truths)
        PlotErrors(preidctions, truths)

    return accuracy

def PlotResults(predictions, truths):
    samples = np.arange(len(predictions))

    plt.figure(figsize=(12, 6))

    plt.plot(samples, truths, label="True Digit", linestyle='-', marker='o', alpha=0.6)
    plt.plot(samples, predictions, label="FPGA Prediction", linestyle='--', marker='x', alpha=0.8)

    plt.xlabel("Sample Index")
    plt.ylabel("Digit Class")
    plt.title("FPGA Digit Classification Output vs Ground Truth")
    plt.legend()
    plt.grid(True)

    plt.tight_layout()

    plt.savefig("fpgaClassificationResults.png", dpi=300, bbox_inches="tight")

    plt.show()

    
def PlotConfusionMatrix(Predictions, Truths):
    CM = confusion_matrix(Truths, Predictions, labels=range(10))

    plt.figure(figsize=(6, 5))
    sns.heatmap(CM, annot=True, fmt="d", cmap="Blues")

    plt.xlabel("Predicted Digit")
    plt.ylabel("True Digit")
    plt.title("FPGA Confusion Matrix")

    plt.tight_layout()
    plt.savefig("fpga_confusion_matrix.png", dpi=300, bbox_inches="tight")
    plt.show()

    
def PlotErrors(Predictions, Truths):
    Samples = np.arange(len(Predictions))
    Errors = [i for i, (p, t) in enumerate(zip(Predictions, Truths)) if p != t]

    plt.figure(figsize=(12, 4))

    plt.scatter(Errors,
                [Predictions[i] for i in Errors],
                label="FPGA Prediction",
                marker="x")

    plt.scatter(Errors,
                [Truths[i] for i in Errors],
                label="True Digit",
                marker="o")

    plt.xlabel("Sample Index")
    plt.ylabel("Digit Class")
    plt.title("Misclassified Samples Only")
    plt.legend()
    plt.grid(True)

    plt.tight_layout()
    plt.savefig("fpga_misclassifications.png", dpi=300, bbox_inches="tight")
    plt.show()



if __name__ == "__main__":
    #RunFullTest("NNToplevelPorts.bit") 
    RunZeroInputTest("NNToplevelPorts.bit")