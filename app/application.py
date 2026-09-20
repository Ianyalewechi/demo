from flask import Flask, jsonify, render_template
import os

app = Flask(__name__)

VERSION = "2.0.0"


@app.route("/")
def home():
    return render_template(
        "index.html",
        version=VERSION,
        environment=os.getenv("ENVIRONMENT", "Azure")
    )


@app.route("/health")
def health():
    return jsonify({"status": "healthy"})


@app.route("/health/ready")
def readiness():
    return jsonify({"status": "ready"})


@app.route("/api/info")
def application_info():
    return jsonify({
        "application": "10Alytics Learning Platform",
        "status": "running",
        "version": VERSION,
        "environment": os.getenv("ENVIRONMENT", "Azure")
    })


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.getenv("PORT", 5000)),
        debug=False
    )
