"use strict";

const cubeElement = document.querySelector("#cube");
const movesElement = document.querySelector("#moves");
const statusElement = document.querySelector("#status");
const doubleIndicator = document.querySelector("#doubleIndicator");
const scrambleButton = document.querySelector("#scrambleButton");
const resetButton = document.querySelector("#resetButton");

let appliedMoves = [];
let doubleMovePending = false;
let requestInProgress = false;

const faceLayout = [
  { face: "u", start: 0, column: 4, row: 1 },
  { face: "r", start: 9, column: 7, row: 4 },
  { face: "f", start: 18, column: 4, row: 4 },
  { face: "d", start: 27, column: 4, row: 7 },
  { face: "l", start: 36, column: 1, row: 4 },
  { face: "b", start: 45, column: 10, row: 4 }
];

const faceNames = {
  U: "sticker-u",
  R: "sticker-r",
  F: "sticker-f",
  D: "sticker-d",
  L: "sticker-l",
  B: "sticker-b"
};

// Construye la rejilla fija de 54 stickers en forma de cruz.
function createCube() {
  faceLayout.forEach((face) => {
    for (let index = 0; index < 9; index += 1) {
      const sticker = document.createElement("div");
      sticker.className = "sticker";
      sticker.dataset.index = String(face.start + index);
      sticker.style.gridColumn = String(face.column + (index % 3));
      sticker.style.gridRow = String(face.row + Math.floor(index / 3));
      cubeElement.appendChild(sticker);
    }
  });
}

// Pinta los stickers según la cadena U, R, F, D, L, B recibida del backend.
function renderFacelets(facelets) {
  const stickers = cubeElement.querySelectorAll(".sticker");
  stickers.forEach((sticker) => {
    const color = facelets[Number(sticker.dataset.index)];
    sticker.className = `sticker ${faceNames[color] || ""}`;
  });
}

// Actualiza la lista visible usando la notación estándar del cubo.
function renderMoves() {
  movesElement.textContent = appliedMoves.length
    ? appliedMoves.map(toNotation).join(" ")
    : "Resuelto";
}

function toNotation(move) {
  const face = move[0].toUpperCase();
  if (move.endsWith("2")) {
    return `${face}2`;
  }
  return move.endsWith("i") ? `${face}'` : face;
}

function setStatus(isLegal) {
  statusElement.textContent = isLegal ? "Estado legal" : "Estado ilegal";
  statusElement.className = isLegal ? "status" : "status invalid";
}

function setBusy(isBusy) {
  requestInProgress = isBusy;
  scrambleButton.disabled = isBusy;
  resetButton.disabled = isBusy;
}

// Solicita al backend el estado correspondiente a la lista de movimientos.
async function updateState() {
  setBusy(true);
  statusElement.textContent = "Actualizando...";
  statusElement.className = "status";
  try {
    const query = encodeURIComponent(appliedMoves.join(","));
    const response = await fetch(`/api/state?moves=${query}`);
    if (!response.ok) {
      throw new Error("No se pudo obtener el estado.");
    }
    const state = await response.json();
    renderFacelets(state.facelets);
    setStatus(state.legal);
    renderMoves();
  } catch (error) {
    statusElement.textContent = error.message;
    statusElement.className = "status error";
  } finally {
    setBusy(false);
  }
}

async function scramble() {
  if (requestInProgress) {
    return;
  }
  setBusy(true);
  try {
    const response = await fetch("/api/scramble?n=25");
    if (!response.ok) {
      throw new Error("No se pudo generar la mezcla.");
    }
    const result = await response.json();
    appliedMoves = result.moves;
    await updateState();
  } catch (error) {
    statusElement.textContent = error.message;
    statusElement.className = "status error";
    setBusy(false);
  }
}

async function reset() {
  if (requestInProgress) {
    return;
  }
  appliedMoves = [];
  await updateState();
}

function handleKey(event) {
  const key = event.key.toLowerCase();
  if (key === "2") {
    doubleMovePending = true;
    doubleIndicator.textContent = "Doble giro: activo";
    event.preventDefault();
    return;
  }
  if (!"urfdlb".includes(key) || requestInProgress) {
    return;
  }
  const suffix = doubleMovePending ? "2" : event.shiftKey ? "i" : "";
  appliedMoves.push(`${key}${suffix}`);
  doubleMovePending = false;
  doubleIndicator.textContent = "";
  updateState();
  event.preventDefault();
}

createCube();
scrambleButton.addEventListener("click", scramble);
resetButton.addEventListener("click", reset);
document.addEventListener("keydown", handleKey);
updateState();
