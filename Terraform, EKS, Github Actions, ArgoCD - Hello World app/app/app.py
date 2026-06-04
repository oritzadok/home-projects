from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Hello World from Ori 3!</p>"

@app.route("/ready")
def ready():
    return jsonify({"status": "ready"}), 200

@app.route("/healthz")
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == "__main__":
    app.run(host='0.0.0.0')