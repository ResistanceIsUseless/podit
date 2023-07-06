from flask import Flask, jsonify
import subprocess

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello World!"

@app.route('/kubeaudit', methods=['POST', 'GET'])
def kubeaudit():
    try:
        # Run kubeaudit and capture the output
        command = f'kubeaudit all'
        subprocess.run(command, shell=True, check=True)
        results = subprocess.check_output(command, shell=True, universal_newlines=True)
        return jsonify({"results": results})
    except subprocess.CalledProcessError as e:
        # Handle any errors that occurred during the execution of kubeaudit
        error_message = f"Error running kubeaudit: {e.output}"
    
@app.route('/docker-bench-security', methods=['POST', 'GET'])
def docker_bench_security():
    try:
        # Run docker-bench and capture the output
        command = f'/opt/docker-bench-security'
        subprocess.run(command, shell=True, check=True)
        results = subprocess.check_output(command, shell=True, universal_newlines=True)
        return jsonify({"results": results})
    except subprocess.CalledProcessError as e:
        # Handle any errors that occurred during the execution of dockerbench
        error_message = f"Error running dockerbench: {e.output}"
        return jsonify({"error": error_message}), 500

@app.route('/PEASS-ng', methods=['POST', 'GET'])
def peass_ng():
    try:
        # Run linpeas and capture the output
        command = f'/opt/linpeas/linpeas.sh -a'
        subprocess.run(command, shell=True, check=True)
        results = subprocess.check_output(command, shell=True, universal_newlines=True)
        return jsonify({"results": results})
    except subprocess.CalledProcessError as e:
        # Handle any errors that occurred during the execution of linpeas
        error_message = f"Error running linpeas: {e.output}"
        return jsonify({"error": error_message}), 500

@app.route('/kubescape', methods=['POST', 'GET'])
def kubescape():
    try:
        # Run kubescape and capture the output
        command = f'kubescape scan framework nsa --exclude-namespaces kube-system'
        subprocess.run(command, shell=True, check=True)
        results = subprocess.check_output(command, shell=True, universal_newlines=True)
        return jsonify({"results": results})
    except subprocess.CalledProcessError as e:
        # Handle any errors that occurred during the execution of kubescape
        error_message = f"Error running kubescape: {e.output}"
        return jsonify({"error": error_message}), 500
    
@app.route('/nmapinfo', methods=['GET'])
def nmap_info():
    try:
        command = f'nmap -iflist'
        subprocess.run(command, shell=True, check=True)
        results = subprocess.check_output(command, shell=True, universal_newlines=True)
        return jsonify({"results": results})
    except subprocess.CalledProcessError as e:
        # Handle any errors that occurred during the execution of nmap
        error_message = f"Error running nmap: {e.output}"
        return jsonify({"error": error_message}), 500

@app.route('/nmap', methods=['POST', 'GET'])
def nmap():
    try:
        # Run nmap and capture the output
        command = f'nmap 172.19.130.0/24 -sV -sC -oX /tmp/nmap_results.xml'
        subprocess.run(command, shell=True, check=True)
        results = subprocess.check_output(command, shell=True, universal_newlines=True)
        return jsonify({"results": results})
    except subprocess.CalledProcessError as e:
        # Handle any errors that occurred during the execution of nmap
        error_message = f"Error running nmap: {e.output}"
        return jsonify({"error": error_message}), 500

@app.route('/nuclei', methods=['POST', 'GET'])
def nuclei():
    try:
        command = f'nmap-parse-output /tmp/nmap_results.xml http-ports http | nuclei'
        subprocess.run(command, shell=True, check=True)
        results = subprocess.check_output(command, shell=True, universal_newlines=True)
        return jsonify({"results": results})
    except subprocess.CalledProcessError as e:
        # Handle any errors that occurred during the execution of nuclei
        error_message = f"Error running nuclei: {e.output}"
        return jsonify({"error": error_message}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080,debug=True)