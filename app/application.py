from flask import Flask
import os

app = Flask(__name__)


@app.route("/")
def home():
    return {
        "application": "10Alytics DevOps Assessment",
        "status": "running",
        "version": "1.0.0"
    }


@app.route("/health")
def health():
    return {
        "status": "healthy"
    }


@app.route("/health/ready")
def readiness():
    return {
        "status": "ready"
    }


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)))