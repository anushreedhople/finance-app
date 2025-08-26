from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from openai import OpenAI
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__, static_folder='Frontend')
CORS(app)

client = OpenAI(api_key=os.getenv("openai_key"))

# simple in-memory chat history for one user/session
chat_history = []

@app.route('/')
def index():
    return send_from_directory('Frontend', 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    return send_from_directory('Frontend', path)

@app.route("/ask", methods=["POST"])
def ask():
    global chat_history
    data = request.get_json()
    message = data.get("message", "")
    age = data.get("age", "")
    monthly_income = data.get("monthly_income", "")
    sectors = data.get("sectors", [])
    future_goals = data.get("future_goals", "")

    # if this is the first message, add system + user context
    if not chat_history:
        system_context = (
            f"You are chatting with a user who is {age} years old, earns ₹{monthly_income} per month, "
            f"spends on {', '.join(sectors) if sectors else 'no specific sectors'}, "
            f"and has the following future goals: {future_goals or 'not specified'}. "
            f"Always answer financial questions in AED."
            "Whenever the user documents something they spent money on, create a clear expense table. "
            "The table must have visible borders for rows and columns. "
            "The table should include at least these columns: Sector, Amount Spent (AED), and % of Total Budget. "
            "Format the table so it is easy to read (use Markdown tables with '|' and '-' to create borders)."
        )
        chat_history.append({"role": "system", "content": "You are a helpful financial advisor."})
        chat_history.append({"role": "system", "content": system_context})

    # add new user message
    chat_history.append({"role": "user", "content": message})

    # get completion with full history
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=chat_history,
        temperature=0.7
    )

    reply = response.choices[0].message.content

    # add assistant reply to history
    chat_history.append({"role": "assistant", "content": reply})

    return jsonify({"reply": reply})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=1111)
