from flask import Flask, jsonify, request
from db_config import user, pw, dsn 
from flask_cors import CORS, cross_origin
from base64 import b64decode
import cx_Oracle as cx
import json
from urllib.parse import unquote

app = Flask(__name__)
cors = CORS(app, resources={r"/*": {"origins": "*"}})

con = cx.connect(user, pw, dsn)
c = con.cursor()

@app.route('/', methods=["POST"])
def solve():
    table = request.json
    for i in range(9):
        for j in range(9):
            c.callproc('put', [i + 1, j + 1, table[i][j]])
    c.callproc('main')
    c.execute("select * from sudoku");
    res = []
    for row in c.fetchall():
        res.append(list(row))
    return jsonify(res)
