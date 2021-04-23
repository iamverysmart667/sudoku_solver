const cells = document.querySelectorAll('.cell')
const [btEasy, btMedium, btHard, btSolve, btClear, btCheck] = document.querySelectorAll('.cell-button');

cells.forEach(c => {
  if (c.innerHTML == 0) c.innerHTML = '&nbsp;&nbsp;';
  c.addEventListener('click', () => document.execCommand('selectAll', false, null))
  c.addEventListener('keyup', e => {
    if (isNaN(String.fromCharCode(e.which))) e.preventDefault()
    else if (c.innerHTML.length > 1) c.innerHTML = String.fromCharCode(e.which)
  })
  c.addEventListener('keydown', e => {
    if (isNaN(String.fromCharCode(e.which))) e.preventDefault()
    else if (c.innerHTML.length == 1) c.innerHTML = String.fromCharCode(e.which)
  })
})

function isValidSudoku(board) {    
  const boxes = [{}, {}, {}, {}, {}, {}, {}, {}, {}];
  const cols = [{}, {}, {}, {}, {}, {}, {}, {}, {}]; 
  const rows = [{}, {}, {}, {}, {}, {}, {}, {}, {}];   

  for (let i = 0; i < 9; i++) {              
    for (let j = 0; j < 9; j++) {            
      const digit = board[i][j];

      if (digit !== 0) {
        const k = Math.floor(j / 3) + (Math.floor(i / 3) * 3);

        if (boxes[k][digit] || cols[j][digit] || rows[i][digit]) {
          return false;
        }

        boxes[k][digit] = cols[j][digit] = rows[i][digit] = true;       
      }
    }
  }

  return true;
};

function generateSudoku(difficulty) {
  axios.get(`https://sugoku.herokuapp.com/board?difficulty=${difficulty}`)
    .then(r => render(r.data.board));
}

function assign(col, data) {
  for (let i = 0; i < 9; i++) {
    col[i].innerHTML = (data[i] === 0 ? "&nbsp;&nbsp" : data[i]);
  }
}

function clear() {
  const rows = document.querySelectorAll('.row');
  rows.forEach(r => {
    if ([...r.children].length == 9) {
      assign([...r.children], [0, 0, 0, 0, 0, 0, 0, 0, 0])
    }
  });
}

function render(a) {
  const rows = document.querySelectorAll('.row');
  for (let i = 1; i < 10; i++) {
    assign([...rows[i].children], a[i - 1]);
  }
}

function check() {
  let a = table();
  let valid = isValidSudoku(a);
  for (let i = 0; i < 9; i++) {
    for (let j = 0; j < 9; j++) {
      if (a[i][j] == 0) {
        alert(valid ? "Incomplete sudoku!" : "Invalid sudoku!")
        return
      }
    }
  }
  alert(valid ? "Good job!" : "Invalid sudoku!")
}

function table() {
  const rows = document.querySelectorAll('.row');
  let a = []
  rows.forEach(r => a.push([...r.children].map(c => c.innerHTML == '&nbsp;&nbsp;' ? 0 : c.innerHTML - '0')))
  a.shift();
  a.pop();
  return a;
}

function solve() {
  let a = table();
  let start = new Date().getTime();
  if (isValidSudoku(a)) {
    axios.post("http://localhost:5000/shit", a)
      .then(r => render(r.data))
      .then(r => {
        let end = new Date().getTime()
        let time = end - start
        console.log(`Execution time: ${time}`)
      })
  }
  else alert("Go fuck yourself!")
}

btEasy.addEventListener('click', () => generateSudoku('easy'));
btMedium.addEventListener('click', () => generateSudoku('medium'));
btHard.addEventListener('click', () => generateSudoku('hard'));
btSolve.addEventListener('click', solve);
btClear.addEventListener('click', clear);
btCheck.addEventListener('click', check);
