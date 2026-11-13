"use strict";

const cubeElement = document.querySelector("#cube");
const mainCube3dElement = document.querySelector("#mainCube3d");
const mainCubeScene = document.querySelector("#mainCubeScene");
const movesElement = document.querySelector("#moves");
const solutionMovesElement = document.querySelector("#solutionMoves");
const statusElement = document.querySelector("#status");
const doubleIndicator = document.querySelector("#doubleIndicator");
const scrambleButton = document.querySelector("#scrambleButton");
const resetButton = document.querySelector("#resetButton");
const solveButton = document.querySelector("#solveButton");
const compareButton = document.querySelector("#compareButton");
const benchmarkButton = document.querySelector("#benchmarkButton");
const validateTabButton = document.querySelector("#validateTabButton");
const methodSelect = document.querySelector("#methodSelect");
const solvePanel = document.querySelector("#solvePanel");
const phaseList = document.querySelector("#phaseList");
const solveSummary = document.querySelector("#solveSummary");
const comparePanel = document.querySelector("#comparePanel");
const benchmarkPanel = document.querySelector("#benchmarkPanel");
const benchmarkStatus = document.querySelector("#benchmarkStatus");
const benchmarkTable = document.querySelector("#benchmarkTable");
const validatePanel = document.querySelector("#validatePanel");
const validationCube = document.querySelector("#validationCube");
const loadCurrentButton = document.querySelector("#loadCurrentButton");
const solvedValidationButton = document.querySelector("#solvedValidationButton");
const validateButton = document.querySelector("#validateButton");
const validationResult = document.querySelector("#validationResult");
const intervalControl = document.querySelector("#intervalControl");
const intervalValue = document.querySelector("#intervalValue");

const comparison = {
  thistle: {
    cube2d: document.querySelector("#thistleCube"),
    cube3d: document.querySelector("#thistleCube3d"),
    stage: document.querySelector("#thistleStage"),
    count: document.querySelector("#thistleCount"),
    card: document.querySelector("#compareThistle")
  },
  cfop: {
    cube2d: document.querySelector("#cfopCube"),
    cube3d: document.querySelector("#cfopCube3d"),
    stage: document.querySelector("#cfopStage"),
    count: document.querySelector("#cfopCount"),
    card: document.querySelector("#compareCfop")
  }
};

let userMoves = [];
let solutionMoves = [];
let doubleMovePending = false;
let requestInProgress = false;
let validationFacelets = [];

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

function createCube(container) {
  container.replaceChildren();

  faceLayout.forEach((face) => {
    for (let index = 0; index < 9; index += 1) {
      const sticker = document.createElement("div");

      sticker.className = "sticker";
      sticker.dataset.index = String(face.start + index);
      sticker.style.gridColumn = String(face.column + (index % 3));
      sticker.style.gridRow = String(face.row + Math.floor(index / 3));

      container.appendChild(sticker);
    }
  });
}

// Cubo 3D real mediante CSS preserve-3d.
// Cada pegatina conserva el índice del facelet recibido del backend.
function create3DCube(container) {
  const faces = [
    { name: "front", start: 18 },
    { name: "right", start: 9 },
    { name: "top", start: 0 },
    { name: "bottom", start: 27 },
    { name: "left", start: 36 },
    { name: "back", start: 45 }
  ];

  const fragment = document.createDocumentFragment();

  faces.forEach(({ name, start }) => {
    const face = document.createElement("div");

    face.className = `cube-face cube-face--${name}`;
    face.setAttribute("aria-hidden", "true");

    for (let row = 0; row < 3; row += 1) {
      for (let col = 0; col < 3; col += 1) {
        const sticker = document.createElement("div");

        sticker.className = "sticker";

        // Reflejar las columnas de las caras laterales.
        const faceColumn =
          (name === "right" || name === "left") ? 2 - col : col;

        sticker.dataset.index = String(
          start + row * 3 + faceColumn
        );

        face.appendChild(sticker);
      }
    }

    fragment.appendChild(face);
  });

  container.replaceChildren(fragment);
  renderFacelets(container, solvedFacelets());
}

const cameraDefaults = {
  main: { x: -27, y: -35 },
  thistle: { x: -27, y: -35 },
  cfop: { x: -27, y: -35 }
};

const cameraState = Object.fromEntries(
  Object.entries(cameraDefaults).map(([name, rotation]) => [
    name,
    { ...rotation }
  ])
);

const cubeElements = {
  main: mainCube3dElement,
  thistle: comparison.thistle.cube3d,
  cfop: comparison.cfop.cube3d
};

function applyCubeCamera(name) {
  const cube = cubeElements[name];
  const rotation = cameraState[name];

  if (!cube || !rotation) return;

  cube.style.setProperty("--rotate-x", `${rotation.x}deg`);
  cube.style.setProperty("--rotate-y", `${rotation.y}deg`);
}

function rotateCubeCamera(name, direction) {
  const rotation = cameraState[name];

  if (!rotation) return;

  if (direction === "reset") {
    rotation.x = cameraDefaults[name].x;
    rotation.y = cameraDefaults[name].y;
  } else if (direction === "left") {
    rotation.y -= name === "main" ? 28 : 34;
  } else if (direction === "right") {
    rotation.y += name === "main" ? 28 : 34;
  } else if (direction === "up") {
    rotation.x -= 22;
  } else if (direction === "down") {
    rotation.x += 22;
  }

  applyCubeCamera(name);
}

// Rotación libre del cubo principal mediante ratón o pantalla táctil.
function enableMainCubeDrag(scene) {
  if (!scene) return;

  let drag = null;

  scene.addEventListener("pointerdown", (event) => {
    if (event.button !== 0) return;

    drag = {
      pointerId: event.pointerId,
      x: event.clientX,
      y: event.clientY
    };

    scene.setPointerCapture(event.pointerId);
    scene.classList.add("is-dragging");
  });

  scene.addEventListener("pointermove", (event) => {
    if (!drag || drag.pointerId !== event.pointerId) return;

    const deltaX = event.clientX - drag.x;
    const deltaY = event.clientY - drag.y;

    drag.x = event.clientX;
    drag.y = event.clientY;

    cameraState.main.y += deltaX * 0.72;
    cameraState.main.x -= deltaY * 0.72;

    applyCubeCamera("main");
  });

  const stopDragging = (event) => {
    if (!drag || drag.pointerId !== event.pointerId) return;

    drag = null;
    scene.classList.remove("is-dragging");

    if (scene.hasPointerCapture(event.pointerId)) {
      scene.releasePointerCapture(event.pointerId);
    }
  };

  scene.addEventListener("pointerup", stopDragging);
  scene.addEventListener("pointercancel", stopDragging);

  scene.addEventListener("lostpointercapture", () => {
    drag = null;
    scene.classList.remove("is-dragging");
  });

  scene.addEventListener("keydown", (event) => {
    const keyMap = {
      ArrowLeft: "left",
      ArrowRight: "right",
      ArrowUp: "up",
      ArrowDown: "down"
    };

    const direction = keyMap[event.key];

    if (!direction) return;

    event.preventDefault();
    rotateCubeCamera("main", direction);
  });
}

// Los botones controlan la orientación de los tres cubos.
document.querySelectorAll("[data-cube][data-rotate]").forEach((button) => {
  button.addEventListener("click", () => {
    rotateCubeCamera(
      button.dataset.cube,
      button.dataset.rotate
    );
  });
});

async function fetchStateForMoves(moves) {
  const query = encodeURIComponent(moves.join(","));

  const response = await fetch(`/api/state?moves=${query}`);

  if (!response.ok) {
    throw new Error("No se pudo obtener el estado de la comparación.");
  }

  return response.json();
}

async function animateComparison(method, result, finished) {
  const view = comparison[method];
  const moves = [];

  const initialState = await fetchStateForMoves(userMoves);

  renderFacelets(view.cube2d, initialState.facelets);
  renderFacelets(view.cube3d, initialState.facelets);

  view.count.textContent = "0";

  for (const step of result.steps) {
    view.stage.textContent = `${step.stage}: ${step.rule}`;

    for (const move of step.moves) {
      moves.push(move);

      const state = await fetchStateForMoves(
        userMoves.concat(moves)
      );

      renderFacelets(view.cube2d, state.facelets);
      renderFacelets(view.cube3d, state.facelets);

      view.count.textContent = String(moves.length);

      await new Promise((resolve) =>
        setTimeout(resolve, Number(intervalControl.value))
      );
    }
  }

  view.stage.textContent = "Terminado";
  view.card.classList.add("completed");

  finished.push(method);

  if (finished.length === 1) {
    view.card.classList.add("winner");
  }
}

function renderComparisonSummary(results, finished) {
  const summary = document.querySelector("#compareSummary");

  summary.innerHTML = `
    <table class="compare-summary-table">
      <thead>
        <tr>
          <th>Método</th>
          <th>Movimientos</th>
          <th>Nodos</th>
          <th>Segundos</th>
        </tr>
      </thead>
      <tbody>
        ${["thistle", "cfop"].map((method) => `
          <tr>
            <td>${method === "thistle" ? "Thistlethwaite" : "CFOP"}</td>
            <td>${results[method].total_moves}</td>
            <td>${results[method].nodes}</td>
            <td>${Number(results[method].seconds).toFixed(4)}</td>
          </tr>
        `).join("")}
      </tbody>
    </table>
    <p>
      Terminó primero:
      ${finished[0] === "thistle" ? "Thistlethwaite" : "CFOP"}
    </p>
  `;
}

async function compare() {
  if (requestInProgress) return;

  setBusy(true);
  showPanel("compare");

  document.querySelector("#compareSummary").textContent = "Resolviendo...";

  Object.values(comparison).forEach((view) => {
    view.card.classList.remove("finished", "completed", "winner");
    view.stage.textContent = "Resolviendo...";
    view.count.textContent = "0";
  });

  try {
    const query = encodeURIComponent(userMoves.join(","));

    const response = await fetch(`/api/compare?moves=${query}`);
    const result = await response.json();

    if (!response.ok) {
      throw new Error(responseError(result, response.status));
    }

    const finished = [];

    await Promise.all([
      animateComparison("thistle", result.thistle, finished),
      animateComparison("cfop", result.cfop, finished)
    ]);

    renderComparisonSummary(result, finished);
  } catch (error) {
    document.querySelector("#compareSummary").textContent = error.message;
  } finally {
    setBusy(false);
  }
}

function renderBenchmark(summaries) {
  benchmarkTable.innerHTML = `
    <table class="compare-summary-table">
      <thead>
        <tr>
          <th>Método</th>
          <th>Movimientos</th>
          <th>Nodos</th>
          <th>Tiempo (s)</th>
        </tr>
      </thead>
      <tbody>
        ${summaries.map((summary) => `
          <tr>
            <td>${summary.method}</td>
            <td>
              ${Number(summary.mean_moves).toFixed(2)}
              / ${summary.min_moves}
              / ${summary.max_moves}
            </td>
            <td>${Number(summary.mean_nodes).toFixed(2)}</td>
            <td>
              ${Number(summary.mean_seconds).toFixed(4)}
              / ${Number(summary.max_seconds).toFixed(4)}
            </td>
          </tr>
        `).join("")}
      </tbody>
    </table>
  `;
}

async function benchmark() {
  if (requestInProgress) return;

  setBusy(true);
  showPanel("benchmark");

  benchmarkStatus.textContent = "Tarda unos segundos...";
  benchmarkTable.innerHTML = "";

  try {
    const response = await fetch("/api/benchmark?n=10&seed=42");
    const result = await response.json();

    if (!response.ok) {
      throw new Error(responseError(result, response.status));
    }

    renderBenchmark(result.summary);

    benchmarkStatus.textContent = "Benchmark completado.";
  } catch (error) {
    benchmarkStatus.textContent = error.message;
  } finally {
    setBusy(false);
  }
}

function renderFacelets(container, facelets) {
  const stickers = container.querySelectorAll(".sticker");

  stickers.forEach((sticker) => {
    const color = facelets[Number(sticker.dataset.index)];

    sticker.setAttribute(
      "class",
      `sticker ${faceNames[color] || ""}`
    );
  });
}

function setValidationFacelets(facelets) {
  validationFacelets = Array.from(facelets);
  renderFacelets(validationCube, validationFacelets);
}

function solvedFacelets() {
  return "U".repeat(9) +
    "R".repeat(9) +
    "F".repeat(9) +
    "D".repeat(9) +
    "L".repeat(9) +
    "B".repeat(9);
}

const validationReasons = {
  piezas_invalidas_o_duplicadas: "Hay piezas repetidas o que faltan",
  orientacion_esquinas_invalida:
    "Una esquina está torcida: la suma de giros no es múltiplo de 3",
  orientacion_aristas_invalida:
    "Una arista está volteada: la suma de giros no es par",
  paridad_permutacion_invalida:
    "Hay piezas intercambiadas: la paridad es imposible",
  invalid_facelets: "Los colores no forman un cubo físico"
};

function showValidationResult(valid, reason) {
  validationResult.className =
    `validation-result ${valid ? "valid" : "invalid"}`;

  validationResult.textContent = valid
    ? "✓ El cubo es válido"
    : `✗ ${validationReasons[reason] || reason}`;
}

async function validateCube() {
  if (requestInProgress) return;

  setBusy(true);

  try {
    const facelets = encodeURIComponent(validationFacelets.join(""));

    const response = await fetch(
      `/api/validate?facelets=${facelets}`
    );

    const result = await response.json();

    if (!response.ok) {
      throw new Error(result.error || "No se pudo validar el cubo.");
    }

    showValidationResult(result.valid, result.reason);
  } catch (error) {
    validationResult.className = "validation-result invalid";
    validationResult.textContent = `✗ ${error.message}`;
  } finally {
    setBusy(false);
  }
}

async function loadCurrentCube() {
  if (requestInProgress) return;

  setBusy(true);

  try {
    const state = await fetchStateForMoves(combinedMoves());

    setValidationFacelets(state.facelets);

    validationResult.textContent = "";
    validationResult.className = "validation-result";
  } catch (error) {
    validationResult.textContent = `✗ ${error.message}`;
    validationResult.className = "validation-result invalid";
  } finally {
    setBusy(false);
  }
}

async function loadDemo(kind) {
  if (requestInProgress) return;

  setBusy(true);

  try {
    const response = await fetch(`/api/demo_illegal?kind=${kind}`);
    const result = await response.json();

    if (!response.ok) {
      throw new Error(result.error || "No se pudo cargar el ejemplo.");
    }

    setValidationFacelets(result.facelets);

    validationResult.textContent = "";
    validationResult.className = "validation-result";
  } catch (error) {
    validationResult.textContent = `✗ ${error.message}`;
    validationResult.className = "validation-result invalid";
  } finally {
    setBusy(false);
  }
}

function renderMoves() {
  movesElement.textContent = userMoves.length
    ? userMoves.map(toNotation).join(" ")
    : "Resuelto";

  if (!solutionMovesElement.textContent.startsWith("Resuelto en")) {
    solutionMovesElement.textContent = solutionMoves.length
      ? solutionMoves.map(toNotation).join(" ")
      : "—";
  }
}

function clearSolution() {
  solutionMoves = [];

  phaseList.innerHTML = "";
  solveSummary.textContent = "";
  solutionMovesElement.textContent = "—";
}

function combinedMoves() {
  return userMoves.concat(solutionMoves);
}

function toNotation(move) {
  const face = move[0].toUpperCase();

  if (move.endsWith("2")) return `${face}2`;

  return move.endsWith("i") ? `${face}'` : face;
}

function updateStatus(message, statusClass = "status") {
  const dot = document.createElement("span");

  dot.className = "status-dot";
  dot.setAttribute("aria-hidden", "true");

  statusElement.className = statusClass;

  statusElement.replaceChildren(
    dot,
    document.createTextNode(` ${message}`)
  );
}

function setStatus(isLegal) {
  updateStatus(
    isLegal ? "✓ Estado legal" : "✕ Estado ilegal",
    isLegal ? "status" : "status invalid"
  );
}

function setBusy(isBusy) {
  requestInProgress = isBusy;

  document.body.classList.toggle("is-loading", isBusy);

  scrambleButton.disabled = isBusy;
  resetButton.disabled = isBusy;
  solveButton.disabled = isBusy;
  compareButton.disabled = isBusy;
  benchmarkButton.disabled = isBusy;
  validateTabButton.disabled = isBusy;
  loadCurrentButton.disabled = isBusy;
  solvedValidationButton.disabled = isBusy;
  validateButton.disabled = isBusy;

  document.querySelectorAll(".demo-button").forEach((button) => {
    button.disabled = isBusy;
  });
}

// Control unificado de paneles: solamente uno visible a la vez.
function showPanel(name) {
  const panels = {
    solve: solvePanel,
    compare: comparePanel,
    validate: validatePanel,
    benchmark: benchmarkPanel
  };

  const buttons = {
    solve: solveButton,
    compare: compareButton,
    validate: validateTabButton,
    benchmark: benchmarkButton
  };

  Object.entries(panels).forEach(([key, panel]) => {
    const isActive = key === name;

    panel.hidden = !isActive;
    panel.setAttribute("aria-hidden", String(!isActive));
  });

  Object.entries(buttons).forEach(([key, button]) => {
    const isActive = key === name;

    button.classList.toggle("active", isActive);
    button.setAttribute("aria-pressed", String(isActive));
  });
}

async function updateState(manageBusy = true) {
  if (manageBusy) setBusy(true);

  updateStatus("Actualizando...");

  try {
    const query = encodeURIComponent(combinedMoves().join(","));

    const response = await fetch(`/api/state?moves=${query}`);

    if (!response.ok) {
      throw new Error("No se pudo obtener el estado.");
    }

    const state = await response.json();

    renderFacelets(cubeElement, state.facelets);
    renderFacelets(mainCube3dElement, state.facelets);

    setStatus(state.legal);
    renderMoves();

    return true;
  } catch (error) {
    updateStatus(error.message, "status error");
    return false;
  } finally {
    if (manageBusy) setBusy(false);
  }
}

async function scramble() {
  if (requestInProgress) return;

  userMoves = [];
  solutionMoves = [];

  clearSolution();
  setBusy(true);

  try {
    const response = await fetch("/api/scramble?n=25");

    if (!response.ok) {
      throw new Error("No se pudo generar la mezcla.");
    }

    const result = await response.json();

    userMoves = result.moves;

    clearSolution();

    await updateState(false);
  } catch (error) {
    updateStatus(error.message, "status error");
  } finally {
    setBusy(false);
  }
}

async function reset() {
  if (requestInProgress) return;

  userMoves = [];
  solutionMoves = [];

  clearSolution();

  await updateState();
}

function renderSolution(phases) {
  solvePanel.hidden = false;
  phaseList.innerHTML = "";

  phases.forEach((phase, index) => {
    const item = document.createElement("article");

    item.className = "phase";
    item.dataset.phase = String(index);

    item.innerHTML = `
      <strong>${phase.stage || phase.name}</strong>
      <span>${phase.rule || ""}</span>
      <span class="phase-moves">
        ${phase.moves.map(toNotation).join(" ") || "—"}
      </span>
      <span>
        ${phase.nodes} nodos · ${Number(phase.seconds).toFixed(4)} s
      </span>
    `;

    phaseList.appendChild(item);
  });
}

function setActivePhase(index) {
  phaseList.querySelectorAll(".phase").forEach((phase, phaseIndex) => {
    phase.classList.toggle("active", phaseIndex === index);
  });
}

function responseError(result, status) {
  if (status === 422 && result.reason) {
    return `Estado ilegal: ${result.reason}`;
  }

  if (status === 400) {
    return result.error || "Movimiento inválido.";
  }

  return result.error || "No se pudo resolver.";
}

async function solve() {
  if (requestInProgress) return;

  clearSolution();

  setBusy(true);
  showPanel("solve");

  solveSummary.textContent = "Calculando...";

  try {
    const query = encodeURIComponent(userMoves.join(","));

    const response = await fetch(
      `/api/solve?method=${methodSelect.value}&moves=${query}`
    );

    const result = await response.json();

    if (!response.ok) {
      throw new Error(responseError(result, response.status));
    }

    renderSolution(result.steps);

    let phaseIndex = 0;

    for (const phase of result.steps) {
      setActivePhase(phaseIndex);

      for (const move of phase.moves) {
        solutionMoves.push(move);

        if (!await updateState(false)) {
          throw new Error("No se pudo actualizar el estado del cubo.");
        }

        await new Promise((resolve) => setTimeout(resolve, 400));
      }

      phaseIndex += 1;
    }

    setActivePhase(-1);

    userMoves = [];

    solveSummary.textContent =
      `Resuelto en ${result.total_moves} movimientos`;

    solutionMovesElement.textContent = solveSummary.textContent;
  } catch (error) {
    solveSummary.textContent = error.message;
    updateStatus(error.message, "status error");
  } finally {
    setBusy(false);
  }
}

function handleKey(event) {
  const key = event.key.toLowerCase();

  if (key === "2") {
    doubleMovePending = true;
    doubleIndicator.textContent = "Doble giro: activo";

    event.preventDefault();
    return;
  }

  if (!"urfdlb".includes(key) || requestInProgress) return;

  clearSolution();

  const suffix = doubleMovePending
    ? "2"
    : event.shiftKey
      ? "i"
      : "";

  userMoves.push(`${key}${suffix}`);

  doubleMovePending = false;
  doubleIndicator.textContent = "";

  updateState();

  event.preventDefault();
}

// Inicialización de los cubos y sus controles.
createCube(cubeElement);
create3DCube(mainCube3dElement);

Object.values(comparison).forEach((view) => {
  createCube(view.cube2d);
  create3DCube(view.cube3d);
});

createCube(validationCube);

Object.keys(cameraState).forEach(applyCubeCamera);

enableMainCubeDrag(mainCubeScene);

// Edición manual de los stickers del cubo de validación.
validationCube.querySelectorAll(".sticker").forEach((sticker) => {
  const index = Number(sticker.dataset.index);
  const center = index % 9 === 4;

  if (!center) {
    sticker.addEventListener("click", () => {
      const colors = ["U", "R", "F", "D", "L", "B"];
      const current = colors.indexOf(validationFacelets[index]);

      validationFacelets[index] = colors[
        (current + 1) % colors.length
      ];

      renderFacelets(validationCube, validationFacelets);
    });
  }
});

// Eventos de los controles principales.
scrambleButton.addEventListener("click", scramble);
resetButton.addEventListener("click", reset);
solveButton.addEventListener("click", solve);
compareButton.addEventListener("click", compare);
benchmarkButton.addEventListener("click", benchmark);

validateTabButton.addEventListener("click", () => showPanel("validate"));

loadCurrentButton.addEventListener("click", loadCurrentCube);

solvedValidationButton.addEventListener("click", () => {
  setValidationFacelets(solvedFacelets());

  validationResult.textContent = "";
  validationResult.className = "validation-result";
});

validateButton.addEventListener("click", validateCube);

document.querySelectorAll(".demo-button").forEach((button) => {
  button.addEventListener("click", () => loadDemo(button.dataset.demoKind));
});

intervalControl.addEventListener("input", () => {
  intervalValue.textContent = intervalControl.value;
});

// Atajos de teclado.
document.addEventListener("keydown", handleKey);

// Estado inicial.
renderFacelets(cubeElement, solvedFacelets());

Object.values(comparison).forEach((view) => {
  renderFacelets(view.cube2d, solvedFacelets());
});

setValidationFacelets(solvedFacelets());

showPanel("solve");

solveSummary.textContent = 'Pulsa "Resolver" para calcular.';

updateState();