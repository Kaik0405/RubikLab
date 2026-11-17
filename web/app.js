"use strict";

const cubeElement = document.querySelector("#cube");
const mainCube3dElement = document.querySelector("#mainCube3d");
const mainCubeScene = document.querySelector("#mainCubeScene");
const validationCube3dElement = document.querySelector("#validationCube3d");
const validationCubeScene = document.querySelector("#validationCubeScene");
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
const validationColorLabel = document.querySelector("#validationColorLabel");
const leftColumn = document.querySelector(".left-column");
const workspaceGrid = document.querySelector(".workspace-grid");
const workspaceNoteCard = document.querySelector(".workspace-note-card");
const loadCurrentButton = document.querySelector("#loadCurrentButton");
const solvedValidationButton = document.querySelector("#solvedValidationButton");
const validateButton = document.querySelector("#validateButton");
const validationResult = document.querySelector("#validationResult");
const intervalControl = document.querySelector("#intervalControl");
const intervalValue = document.querySelector("#intervalValue");
const navSolveButton = document.querySelector("#navSolveButton");
const navCompareButton = document.querySelector("#navCompareButton");
const navBenchmarkButton = document.querySelector("#navBenchmarkButton");

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
let selectedValidationColor = "U";

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
      const faceletIndex = face.start + index;
      sticker.dataset.index = String(faceletIndex);
      sticker.style.gridColumn = String(face.column + (index % 3));
      sticker.style.gridRow = String(face.row + Math.floor(index / 3));

      if (container.id === "validationCube") {
        const isCenter = faceletIndex % 9 === 4;
        sticker.tabIndex = isCenter ? -1 : 0;
        sticker.setAttribute("role", isCenter ? "img" : "button");
        sticker.setAttribute("aria-label", isCenter
          ? "Centro fijo de la cara"
          : `Pegatina editable ${faceletIndex + 1}`);
        if (isCenter) sticker.setAttribute("aria-disabled", "true");
      }

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
    face.setAttribute("aria-label", `${name} face`);

    for (let row = 0; row < 3; row += 1) {
      for (let col = 0; col < 3; col += 1) {
        const sticker = document.createElement("div");

        sticker.className = "sticker";

        // Reflejar las columnas de las caras laterales.
        const faceColumn =
          (name === "right" || name === "left") ? 2 - col : col;

        const faceletIndex = start + row * 3 + faceColumn;
        sticker.dataset.index = String(faceletIndex);

        if (container.id === "validationCube3d") {
          const isCenter = faceletIndex % 9 === 4;
          sticker.tabIndex = isCenter ? -1 : 0;
          sticker.setAttribute("role", isCenter ? "img" : "button");
          sticker.setAttribute("aria-label", isCenter
            ? `Centro de la cara ${name}`
            : `Pegatina editable ${faceletIndex + 1}`);
          if (isCenter) sticker.setAttribute("aria-disabled", "true");
        }

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
  validation: { x: -27, y: -35 },
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
  validation: validationCube3dElement,
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

// Rotación libre de las vistas 3D mediante ratón, tacto o teclado.
function enableCubeDrag(scene, cameraName = "main") {
  if (!scene) return;

  let drag = null;

  scene.addEventListener("pointerdown", (event) => {
    if (event.button !== 0) return;
    if (event.target.closest("button")) return;

    drag = {
      pointerId: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      startX: event.clientX,
      startY: event.clientY,
      moved: false,
      sticker: cameraName === "validation"
        ? event.target.closest(".sticker[role='button']")
        : null
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
    if (Math.hypot(event.clientX - drag.startX, event.clientY - drag.startY) > 5) {
      drag.moved = true;
    }

    cameraState[cameraName].y += deltaX * 0.72;
    cameraState[cameraName].x -= deltaY * 0.72;
    applyCubeCamera(cameraName);
  });

  const stopDragging = (event) => {
    if (!drag || drag.pointerId !== event.pointerId) return;
    const completedDrag = drag;
    drag = null;
    scene.classList.remove("is-dragging");
    if (cameraName === "validation" && !completedDrag.moved && completedDrag.sticker) {
      paintValidationSticker(completedDrag.sticker);
    }
    if (scene.hasPointerCapture(event.pointerId)) scene.releasePointerCapture(event.pointerId);
  };

  scene.addEventListener("pointerup", stopDragging);
  scene.addEventListener("pointercancel", stopDragging);
  scene.addEventListener("lostpointercapture", () => {
    drag = null;
    scene.classList.remove("is-dragging");
  });
  scene.addEventListener("keydown", (event) => {
    const keyMap = { ArrowLeft: "left", ArrowRight: "right", ArrowUp: "up", ArrowDown: "down" };
    const direction = keyMap[event.key];
    if (!direction) return;
    event.preventDefault();
    rotateCubeCamera(cameraName, direction);
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

// Movimiento visual sincronizado: el cubo realiza un giro 3D breve por cada
// movimiento lógico. El estado de colores solo se actualiza al terminar el giro.
const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

function moveAxis(move) {
  const face = String(move || "").toLowerCase()[0];
  if (face === "u" || face === "d") return "Y";
  if (face === "r" || face === "l") return "X";
  return "Z";
}

function moveAngle(move) {
  const token = String(move || "").toLowerCase();
  const direction = token.endsWith("i") ? -1 : 1;
  return 90 * (token.endsWith("2") ? 2 : 1) * direction;
}

async function animateCubeTurn(cube, move, duration = null) {
  if (!cube) return;
  const ms = Math.max(110, duration ?? Number(intervalControl?.value || 180));
  if (reducedMotion.matches || !cube.animate) {
    cube.classList.add("cube-turn-settle");
    await new Promise((resolve) => setTimeout(resolve, 35));
    cube.classList.remove("cube-turn-settle");
    return;
  }

  const axis = moveAxis(move);
  const angle = moveAngle(move);
  const camera = `rotateX(${cameraState.main?.x ?? -27}deg) rotateY(${cameraState.main?.y ?? -35}deg)`;
  const isComparison = cube === comparison.thistle.cube3d || cube === comparison.cfop.cube3d;
  const cameraName = isComparison ? (cube === comparison.thistle.cube3d ? "thistle" : "cfop") : "main";
  const rotation = cameraState[cameraName] || { x: -27, y: -35 };
  const base = `rotateX(${rotation.x}deg) rotateY(${rotation.y}deg)`;
  const spin = `${base} rotate${axis}(${angle}deg)`;
  const half = `${base} rotate${axis}(${angle * 0.52}deg) scale(1.035)`;

  const animation = cube.animate([
    { transform: base, offset: 0 },
    { transform: half, offset: 0.52 },
    { transform: spin, offset: 0.86 },
    { transform: base, offset: 1 }
  ], {
    duration: Math.min(520, Math.max(170, ms * 0.92)),
    easing: "cubic-bezier(.2,.78,.2,1)",
    fill: "none"
  });
  try { await animation.finished; } catch (_) { /* animación cancelada */ }
}

function staggerIn(container, selector = ":scope > *", baseDelay = 55) {
  if (!container) return;
  const items = Array.from(container.querySelectorAll(selector));
  items.forEach((item, index) => {
    item.classList.remove("motion-stagger-in");
    item.style.setProperty("--motion-delay", `${Math.min(index, 10) * baseDelay}ms`);
    void item.offsetWidth;
    item.classList.add("motion-stagger-in");
  });
}

function animateValue(element, target, suffix = "", decimals = 0) {
  if (!element) return;
  const end = Number(target) || 0;
  if (reducedMotion.matches) {
    element.textContent = `${end.toFixed(decimals)}${suffix}`;
    return;
  }
  const start = performance.now();
  const duration = 720;
  const tick = (now) => {
    const progress = Math.min(1, (now - start) / duration);
    const eased = 1 - Math.pow(1 - progress, 3);
    element.textContent = `${(end * eased).toFixed(decimals)}${suffix}`;
    if (progress < 1) requestAnimationFrame(tick);
  };
  requestAnimationFrame(tick);
}

function renderMetricChart(rows, target) {
  if (!target || !rows.length) return;
  const max = Math.max(1, ...rows.flatMap((row) => [row.thistle.seconds, row.cfop.seconds]));
  const points = (method) => rows.map((row, index) => {
    const x = 24 + index * (252 / Math.max(1, rows.length - 1));
    const y = 94 - (row[method].seconds / max) * 70;
    return `${x},${y}`;
  }).join(" ");
  const bars = rows.map((row, index) => {
    const x = 24 + index * (252 / rows.length);
    const width = Math.max(4, 15 / Math.max(1, rows.length / 5));
    const th = (row.thistle.seconds / max) * 64;
    const cf = (row.cfop.seconds / max) * 64;
    return `<rect class="chart-bar chart-bar-thistle" x="${x}" y="${94-th}" width="${width}" height="${th}" rx="3" style="--bar-delay:${index*55}ms"/><rect class="chart-bar chart-bar-cfop" x="${x+width+3}" y="${94-cf}" width="${width}" height="${cf}" rx="3" style="--bar-delay:${index*55+35}ms"/>`;
  }).join("");
  target.innerHTML = `
    <div class="motion-chart-card">
      <div class="motion-chart-heading"><div><span class="benchmark-eyebrow">TENDENCIA DE RENDIMIENTO</span><strong>Tiempo por prueba</strong></div><div class="motion-chart-legend"><span class="legend-thistle">Thistle</span><span class="legend-cfop">CFOP</span></div></div>
      <svg class="motion-chart" viewBox="0 0 300 112" role="img" aria-label="Comparación del tiempo de resolución por prueba">
        <path class="chart-gridline" d="M20 24H286 M20 58H286 M20 94H286"/>
        ${bars}
        <polyline class="chart-line chart-line-thistle" points="${points("thistle")}"/>
        <polyline class="chart-line chart-line-cfop" points="${points("cfop")}"/>
      </svg>
      <div class="motion-chart-axis"><span>PRIMERA PRUEBA</span><span>${rows.length} / 10</span><span>ÚLTIMA</span></div>
    </div>`;
  staggerIn(target, ".motion-chart-card", 0);
}

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

      await animateCubeTurn(view.cube3d, move);
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
    <div class="compare-chart motion-chart-card">
      <div class="motion-chart-heading"><div><span class="benchmark-eyebrow">COMPARACIÓN DIRECTA</span><strong>Movimientos y tiempo</strong></div><div class="motion-chart-legend"><span class="legend-thistle">Thistle</span><span class="legend-cfop">CFOP</span></div></div>
      ${["thistle", "cfop"].map((method) => {
        const item = results[method];
        const maxMoves = Math.max(results.thistle.total_moves, results.cfop.total_moves, 1);
        const maxTime = Math.max(results.thistle.seconds, results.cfop.seconds, 0.0001);
        return `<div class="compare-chart-row"><span>${method === "thistle" ? "Thistlethwaite" : "CFOP"}</span><div class="compare-chart-track"><i class="${method}" style="--target-width:${(item.total_moves/maxMoves)*100}%"></i></div><strong>${item.total_moves} mov.</strong><small>${Number(item.seconds).toFixed(4)} s</small></div>`;
      }).join("")}
    </div>
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

function createBenchmarkView() {
  benchmarkTable.innerHTML = `
    <section class="benchmark-dashboard">
      <div class="benchmark-overview">
        <div class="benchmark-progress-copy">
          <span class="benchmark-eyebrow">EJECUCIÓN EN DIRECTO</span>
          <strong id="benchmarkProgressTitle">Preparando pruebas...</strong>
          <span id="benchmarkProgressText">Los dos métodos resolverán las mismas mezclas.</span>
        </div>
        <div class="benchmark-progress-track">
          <span id="benchmarkProgressBar"></span>
        </div>
      </div>

      <div class="benchmark-live-grid">
        <article class="benchmark-method benchmark-thistle" id="benchmarkThistle">
          <header class="benchmark-method-heading">
            <div>
              <span class="benchmark-method-kicker">MÉTODO 01</span>
              <h3>Thistlethwaite</h3>
            </div>
            <span class="benchmark-live-state" id="benchmarkThistleState">En espera</span>
          </header>
          <div class="benchmark-cube-stage">
            <div class="benchmark-cube-net cube-net" id="benchmarkThistleCube" aria-label="Cubo Thistlethwaite"></div>
          </div>
          <div class="benchmark-scramble">
            <span>MEZCLA ACTUAL</span>
            <p id="benchmarkThistleScramble">Esperando mezcla...</p>
          </div>
          <div class="benchmark-solution">
            <div class="benchmark-solution-heading">
              <span>MOVIMIENTOS EJECUTADOS</span>
              <strong id="benchmarkThistleCount">0</strong>
            </div>
            <p id="benchmarkThistleMoves">—</p>
          </div>
          <div class="benchmark-phase">
            <div class="benchmark-phase-heading">
              <span id="benchmarkThistleStage">Fase pendiente</span>
              <span id="benchmarkThistlePercent">0%</span>
            </div>
            <div class="benchmark-phase-track"><span id="benchmarkThistleBar"></span></div>
          </div>
        </article>

        <article class="benchmark-method benchmark-cfop" id="benchmarkCfop">
          <header class="benchmark-method-heading">
            <div>
              <span class="benchmark-method-kicker">MÉTODO 02</span>
              <h3>CFOP</h3>
            </div>
            <span class="benchmark-live-state" id="benchmarkCfopState">En espera</span>
          </header>
          <div class="benchmark-cube-stage">
            <div class="benchmark-cube-net cube-net" id="benchmarkCfopCube" aria-label="Cubo CFOP"></div>
          </div>
          <div class="benchmark-scramble">
            <span>MEZCLA ACTUAL</span>
            <p id="benchmarkCfopScramble">Esperando mezcla...</p>
          </div>
          <div class="benchmark-solution">
            <div class="benchmark-solution-heading">
              <span>MOVIMIENTOS EJECUTADOS</span>
              <strong id="benchmarkCfopCount">0</strong>
            </div>
            <p id="benchmarkCfopMoves">—</p>
          </div>
          <div class="benchmark-phase">
            <div class="benchmark-phase-heading">
              <span id="benchmarkCfopStage">Fase pendiente</span>
              <span id="benchmarkCfopPercent">0%</span>
            </div>
            <div class="benchmark-phase-track"><span id="benchmarkCfopBar"></span></div>
          </div>
        </article>
      </div>

      <div class="benchmark-results">
        <div class="benchmark-results-heading">
          <div>
            <span class="benchmark-eyebrow">ANÁLISIS</span>
            <h3>Rendimiento acumulado</h3>
          </div>
          <span class="benchmark-results-count" id="benchmarkResultsCount">0 / 10 pruebas</span>
        </div>
        <div class="benchmark-metric-grid" id="benchmarkMetricGrid">
          <div class="benchmark-empty">Las métricas aparecerán a medida que se completen las pruebas.</div>
        </div>
        <div class="benchmark-history-wrap">
          <div class="benchmark-history-heading">
            <strong>Historial de pruebas</strong>
            <span>Movimientos por mezcla</span>
          </div>
          <div class="benchmark-history" id="benchmarkHistory">
            <span class="benchmark-empty">Esperando la primera prueba...</span>
          </div>
        </div>
      </div>
    </section>
  `;

  const thistleCube = document.querySelector("#benchmarkThistleCube");
  const cfopCube = document.querySelector("#benchmarkCfopCube");
  createCube(thistleCube);
  createCube(cfopCube);

  return {
    thistle: benchmarkMethodView("Thistle"),
    cfop: benchmarkMethodView("Cfop")
  };
}

function benchmarkMethodView(prefix) {
  return {
    card: document.querySelector(`#benchmark${prefix}`),
    cube: document.querySelector(`#benchmark${prefix}Cube`),
    state: document.querySelector(`#benchmark${prefix}State`),
    scramble: document.querySelector(`#benchmark${prefix}Scramble`),
    count: document.querySelector(`#benchmark${prefix}Count`),
    moves: document.querySelector(`#benchmark${prefix}Moves`),
    stage: document.querySelector(`#benchmark${prefix}Stage`),
    percent: document.querySelector(`#benchmark${prefix}Percent`),
    bar: document.querySelector(`#benchmark${prefix}Bar`)
  };
}

function benchmarkSetProgress(completed, total, message) {
  const title = document.querySelector("#benchmarkProgressTitle");
  const text = document.querySelector("#benchmarkProgressText");
  const bar = document.querySelector("#benchmarkProgressBar");

  title.textContent = `Prueba ${Math.min(completed + 1, total)} de ${total}`;
  text.textContent = message;
  bar.style.width = `${(completed / total) * 100}%`;
  document.querySelector("#benchmarkResultsCount").textContent =
    `${completed} / ${total} pruebas`;
}

function benchmarkRenderMetrics(rows) {
  const grid = document.querySelector("#benchmarkMetricGrid");
  if (!rows.length) return;

  const metrics = ["thistle", "cfop"].map((method) => {
    const values = rows.map((row) => row[method]);
    const average = (key) =>
      values.reduce((sum, item) => sum + Number(item[key]), 0) / values.length;

    return {
      method,
      moves: average("total_moves"),
      nodes: average("nodes"),
      seconds: average("seconds")
    };
  });

  const fastest = metrics.reduce((a, b) => a.seconds <= b.seconds ? a : b);
  const fewestMoves = metrics.reduce((a, b) => a.moves <= b.moves ? a : b);
  const fewestNodes = metrics.reduce((a, b) => a.nodes <= b.nodes ? a : b);

  grid.innerHTML = metrics.map((metric) => `
    <article class="benchmark-metric-card ${metric.method}">
      <span>${metric.method === "thistle" ? "THISTLETHWAITE" : "CFOP"}</span>
      <div class="benchmark-metric-values">
        <div><strong>${metric.moves.toFixed(2)}</strong><small>movimientos medios</small></div>
        <div><strong>${Math.round(metric.nodes).toLocaleString("es-ES")}</strong><small>nodos medios</small></div>
        <div><strong>${metric.seconds.toFixed(4)} s</strong><small>tiempo medio</small></div>
      </div>
    </article>
  `).join("");

  const note = document.createElement("p");
  note.className = "benchmark-winners";
  note.textContent =
    `Más rápido: ${fastest.method === "thistle" ? "Thistlethwaite" : "CFOP"} · ` +
    `Menos movimientos: ${fewestMoves.method === "thistle" ? "Thistlethwaite" : "CFOP"} · ` +
    `Menos nodos: ${fewestNodes.method === "thistle" ? "Thistlethwaite" : "CFOP"}`;
  grid.appendChild(note);
  const chartHost = document.createElement("div");
  chartHost.className = "benchmark-chart-host";
  grid.appendChild(chartHost);
  renderMetricChart(rows, chartHost);
  grid.querySelectorAll(".benchmark-metric-card strong").forEach((value) => {
    const raw = Number(value.textContent.replace(/[^0-9.]/g, ""));
    if (Number.isFinite(raw)) animateValue(value, raw, value.textContent.includes(" s") ? " s" : "", value.textContent.includes(" s") ? 4 : 2);
  });
}

function benchmarkRenderHistory(rows) {
  const history = document.querySelector("#benchmarkHistory");
  history.innerHTML = rows.map((row, index) => {
    const t = row.thistle.total_moves;
    const c = row.cfop.total_moves;
    const max = Math.max(t, c, 1);
    return `
      <div class="benchmark-history-row">
        <span class="benchmark-history-index">${String(index + 1).padStart(2, "0")}</span>
        <div class="benchmark-history-bars">
          <div class="benchmark-history-bar-line">
            <span>TH</span><i><b style="width:${(t / max) * 100}%"></b></i><strong>${t}</strong>
          </div>
          <div class="benchmark-history-bar-line">
            <span>CF</span><i><b style="width:${(c / max) * 100}%"></b></i><strong>${c}</strong>
          </div>
        </div>
      </div>
    `;
  }).join("");
}

async function animateBenchmarkMethod(method, result, scrambleMoves, view) {
  const allMoves = [];
  const totalMoves = Number(result.total_moves) || 0;
  let executed = 0;

  view.card.classList.remove("completed", "winner");
  view.state.textContent = "Resolviendo";
  view.scramble.textContent = scrambleMoves.map(toNotation).join(" ");
  view.moves.textContent = "—";
  view.count.textContent = "0";
  view.bar.style.width = "0%";
  view.percent.textContent = "0%";

  const initialState = await fetchStateForMoves(scrambleMoves);
  renderFacelets(view.cube, initialState.facelets);

  for (const step of result.steps) {
    view.stage.textContent = step.stage || step.name || "Resolviendo";
    const phaseMoves = step.moves || [];

    for (const move of phaseMoves) {
      allMoves.push(move);
      executed += 1;

      const state = await fetchStateForMoves(scrambleMoves.concat(allMoves));
      view.cube.classList.remove("net-turning");
      void view.cube.offsetWidth;
      view.cube.classList.add("net-turning");
      renderFacelets(view.cube, state.facelets);

      view.count.textContent = String(executed);
      view.moves.textContent = allMoves.map(toNotation).join(" ");
      const progress = totalMoves ? Math.min(100, (executed / totalMoves) * 100) : 100;
      view.bar.style.width = `${progress}%`;
      view.percent.textContent = `${Math.round(progress)}%`;

      await new Promise((resolve) =>
        setTimeout(resolve, Math.max(90, Number(intervalControl.value) || 180))
      );
    }
  }

  view.stage.textContent = "Cubo resuelto";
  view.state.textContent = "Completado";
  view.bar.style.width = "100%";
  view.percent.textContent = "100%";
  view.card.classList.add("completed");
}

function benchmarkNormalizeResult(result) {
  return {
    total_moves: Number(result.total_moves),
    nodes: Number(result.nodes),
    seconds: Number(result.seconds),
    steps: result.steps || []
  };
}

async function benchmark() {
  if (requestInProgress) return;

  setBusy(true);
  showPanel("benchmark");
  benchmarkStatus.textContent = "Preparando el benchmark visual...";
  benchmarkTable.innerHTML = "";
  const benchmarkTag = benchmarkPanel.querySelector(".benchmark-tag");
  if (benchmarkTag) benchmarkTag.textContent = "10 ejecuciones · mezclas compartidas";

  const totalTests = 10;
  const rows = [];
  const views = createBenchmarkView();

  try {
    for (let index = 0; index < totalTests; index += 1) {
      benchmarkSetProgress(index, totalTests, "Generando una mezcla compartida para ambos métodos...");

      const scrambleResponse = await fetch("/api/scramble?n=25");
      const scrambleResult = await scrambleResponse.json();
      if (!scrambleResponse.ok) {
        throw new Error(scrambleResult.error || "No se pudo generar la mezcla.");
      }

      const scrambleMoves = scrambleResult.moves;
      const query = encodeURIComponent(scrambleMoves.join(","));
      const compareResponse = await fetch(`/api/compare?moves=${query}`);
      const compareResult = await compareResponse.json();

      if (!compareResponse.ok) {
        throw new Error(responseError(compareResult, compareResponse.status));
      }

      const thistle = benchmarkNormalizeResult(compareResult.thistle);
      const cfop = benchmarkNormalizeResult(compareResult.cfop);

      views.thistle.scramble.textContent = scrambleMoves.map(toNotation).join(" ");
      views.cfop.scramble.textContent = scrambleMoves.map(toNotation).join(" ");

      benchmarkSetProgress(index, totalTests,
        `Mezcla ${index + 1}: animando las soluciones de Thistlethwaite y CFOP.`);

      await Promise.all([
        animateBenchmarkMethod("thistle", thistle, scrambleMoves, views.thistle),
        animateBenchmarkMethod("cfop", cfop, scrambleMoves, views.cfop)
      ]);

      rows.push({ thistle, cfop });
      benchmarkRenderMetrics(rows);
      benchmarkRenderHistory(rows);

      benchmarkSetProgress(index + 1, totalTests,
        index + 1 === totalTests
          ? "Todas las mezclas se han resuelto."
          : `Prueba ${index + 1} completada. Preparando la siguiente mezcla...`);
    }

    const progressBar = document.querySelector("#benchmarkProgressBar");
    progressBar.style.width = "100%";
    document.querySelector("#benchmarkProgressTitle").textContent = "Benchmark completado";
    benchmarkStatus.textContent = "Benchmark completado. Ambos métodos resolvieron las mismas 10 mezclas.";
  } catch (error) {
    benchmarkStatus.textContent = error.message;
    const title = document.querySelector("#benchmarkProgressTitle");
    if (title) title.textContent = "Benchmark interrumpido";
  } finally {
    setBusy(false);
  }
}

function renderFacelets(container, facelets) {
  if (!container) return;
  const stickers = container.querySelectorAll(".sticker");

  stickers.forEach((sticker) => {
    const index = Number(sticker.dataset.index);
    const color = facelets[index];
    sticker.className = `sticker ${faceNames[color] || ""}`;

    if (container.id === "validationCube3d" || container.id === "validationCube") {
      const colorNames = { U: "blanco", R: "rojo", F: "verde", D: "amarillo", L: "naranja", B: "azul" };
      const isCenter = index % 9 === 4;
      sticker.setAttribute("aria-label", `${isCenter ? "Centro fijo" : "Pegatina editable"}: ${colorNames[color] || "sin color"}`);
    }
  });
}

function setValidationFacelets(facelets) {
  validationFacelets = Array.from(facelets);
  renderFacelets(validationCube, validationFacelets);
  renderFacelets(validationCube3dElement, validationFacelets);
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

  const navigation = {
    solve: navSolveButton,
    compare: navCompareButton,
    validate: validateTabButton,
    benchmark: navBenchmarkButton
  };

  const pageCopy = {
    solve: {
      title: "Resolver cubo",
      description: "Explora el estado, ejecuta una resolución y observa cada etapa del algoritmo."
    },
    compare: {
      title: "Comparar métodos",
      description: "Pon a prueba Thistlethwaite y CFOP sobre el mismo estado y observa sus soluciones en paralelo."
    },
    validate: {
      title: "Validar estado",
      description: "Inspecciona las piezas y comprueba si la configuración representa un cubo físicamente posible."
    },
    benchmark: {
      title: "Benchmark",
      description: "Analiza movimientos, nodos y tiempos con un conjunto de mezclas compartidas."
    }
  };

  Object.entries(panels).forEach(([key, panel]) => {
    if (!panel) return;
    const isActive = key === name;
    panel.hidden = !isActive;
    panel.setAttribute("aria-hidden", String(!isActive));
  });

  Object.entries(navigation).forEach(([key, button]) => {
    if (!button) return;
    const isActive = key === name;
    button.classList.toggle("active", isActive);
    button.setAttribute("aria-current", isActive ? "page" : "false");
    button.setAttribute("aria-pressed", String(isActive));
  });

  const copy = pageCopy[name];
  const title = document.querySelector("#pageTitle");
  const description = document.querySelector("#pageDescription");
  const breadcrumb = document.querySelector("#activeBreadcrumb");
  if (copy && title) title.textContent = copy.title;
  if (copy && description) description.textContent = copy.description;
  if (copy && breadcrumb) breadcrumb.textContent = copy.title;

  const activePanel = panels[name];
  const isSolveWorkspace = name === "solve";

  // Resolver conserva el layout de cubo + operaciones. Las demás secciones
  // usan todo el ancho disponible y no heredan el cubo principal.
  if (leftColumn) leftColumn.hidden = !isSolveWorkspace;
  if (workspaceGrid) workspaceGrid.classList.toggle("is-section-wide", !isSolveWorkspace);
  if (workspaceNoteCard) workspaceNoteCard.hidden = !isSolveWorkspace;

  const heading = document.querySelector(".page-heading");
  [heading, document.querySelector(".controls-card")]
    .filter(Boolean)
    .forEach((element, index) => {
      element.classList.remove("motion-page-in");
      element.style.setProperty("--motion-delay", `${index * 95}ms`);
      void element.offsetWidth;
      element.classList.add("motion-page-in");
    });
  if (isSolveWorkspace && leftColumn) {
    staggerIn(leftColumn, ".cube-card, .controls-card, .cube-3d-block, .cube-2d-block, .action-grid, .settings-row, .moves-panel", 68);
  }
  if (activePanel) {
    staggerIn(activePanel, ".panel-header, .solve-overview, .phase-section-header, .phase-list, .phase-metrics-chart, .methods-overview, .compare-intro, .compare-launch-card, .method-heading, .comparison-visuals, .comparison-stage, .comparison-count, .compare-results-header, .compare-summary, .validation-layout, .validation-cube-wrap, .validation-net-wrap, .validation-tool-group, .validation-rules, .benchmark-launch-card, .benchmark-status, .benchmark-dashboard > *, .benchmark-method, .benchmark-results", 62);
  }
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
  updateStatus("Mezclando cubo...");
  try {
    const response = await fetch("/api/scramble?n=25");
    const result = await response.json();
    if (!response.ok) throw new Error(result.error || "No se pudo generar la mezcla.");

    const scrambleMoves = result.moves || [];
    userMoves = [];
    renderMoves();
    for (let index = 0; index < scrambleMoves.length; index += 1) {
      const move = scrambleMoves[index];
      const nextMoves = scrambleMoves.slice(0, index + 1);
      const state = await fetchStateForMoves(nextMoves);
      await animateCubeTurn(mainCube3dElement, move);
      userMoves = nextMoves;
      renderFacelets(cubeElement, state.facelets);
      renderFacelets(mainCube3dElement, state.facelets);
      renderMoves();
      setStatus(state.legal);
      await new Promise((resolve) => setTimeout(resolve, Math.max(25, Number(intervalControl.value) * 0.28)));
    }
    updateStatus(`Mezcla completada · ${scrambleMoves.length} movimientos`);
  } catch (error) {
    updateStatus(error.message, "status error");
  } finally {
    setBusy(false);
  }
}

async function reset() {
  if (requestInProgress) return;
  setBusy(true);
  try {
    const reverseMoves = userMoves.slice().reverse().map((move) => {
      if (move.endsWith("2")) return move;
      return move.endsWith("i") ? move[0] : `${move[0]}i`;
    });
    for (const move of reverseMoves) {
      await animateCubeTurn(mainCube3dElement, move, Math.min(210, Number(intervalControl.value) || 180));
    }
    userMoves = [];
    solutionMoves = [];
    clearSolution();
    await updateState(false);
  } finally {
    setBusy(false);
  }
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
  staggerIn(phaseList, ".phase", 75);

  const previousChart = document.querySelector("#phaseMetricsChart");
  if (previousChart) previousChart.remove();
  const chart = document.createElement("section");
  chart.id = "phaseMetricsChart";
  chart.className = "phase-metrics-chart motion-chart-card";
  const maxTime = Math.max(0.0001, ...phases.map((phase) => Number(phase.seconds) || 0));
  chart.innerHTML = `
    <div class="motion-chart-heading"><div><span class="benchmark-eyebrow">PERFIL DEL ALGORITMO</span><strong>Tiempo por fase</strong></div><span class="phase-counter">${phases.length} FASES</span></div>
    <div class="phase-time-bars">${phases.map((phase, index) => {
      const value = Number(phase.seconds) || 0;
      const width = Math.max(1.5, value / maxTime * 100);
      return `<div class="phase-time-row"><span>${String(index + 1).padStart(2, "0")} · ${phase.stage || phase.name}</span><i><b style="--phase-width:${width}%;--bar-delay:${index * 85}ms"></b></i><strong>${value.toFixed(4)} s</strong></div>`;
    }).join("")}</div>`;
  phaseList.insertAdjacentElement("afterend", chart);
  staggerIn(chart, ".phase-time-row", 75);
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
        const state = await fetchStateForMoves(combinedMoves());
        await animateCubeTurn(mainCube3dElement, move);
        renderFacelets(cubeElement, state.facelets);
        renderFacelets(mainCube3dElement, state.facelets);
        setStatus(state.legal);
        renderMoves();
        await new Promise((resolve) => setTimeout(resolve, Math.max(25, Number(intervalControl.value) * 0.28 || 50)));
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
  if (!navSolveButton.classList.contains("active")) return;
  const target = event.target;
  if (target && target.closest("input, textarea, select, button, a, [contenteditable='true']")) return;

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
create3DCube(validationCube3dElement);

Object.keys(cameraState).forEach(applyCubeCamera);

enableCubeDrag(mainCubeScene, "main");
enableCubeDrag(validationCubeScene, "validation");

const validationColorNames = {
  U: "blanco", R: "rojo", F: "verde", D: "amarillo", L: "naranja", B: "azul"
};

function selectValidationColor(color) {
  if (!faceNames[color]) return;
  selectedValidationColor = color;
  document.querySelectorAll(".validation-swatch").forEach((button) => {
    const selected = button.dataset.faceletColor === color;
    button.classList.toggle("is-selected", selected);
    button.setAttribute("aria-pressed", String(selected));
  });
  if (validationColorLabel) {
    validationColorLabel.textContent = `Color seleccionado: ${validationColorNames[color]}`;
  }
}

function paintValidationSticker(sticker) {
  if (!sticker || !sticker.classList.contains("sticker")) return;
  const index = Number(sticker.dataset.index);
  if (!Number.isInteger(index) || index % 9 === 4) return;

  validationFacelets[index] = selectedValidationColor;
  renderFacelets(validationCube, validationFacelets);
  renderFacelets(validationCube3dElement, validationFacelets);
  validationResult.textContent = "";
  validationResult.className = "validation-result";
}

// La red 2D y el cubo 3D comparten el mismo arreglo de facelets.
validationCube.addEventListener("click", (event) => {
  const sticker = event.target.closest(".sticker");
  if (sticker) paintValidationSticker(sticker);
});

validationCube.addEventListener("keydown", (event) => {
  if (event.key !== "Enter" && event.key !== " ") return;
  const sticker = event.target.closest(".sticker[role='button']");
  if (!sticker) return;
  event.preventDefault();
  paintValidationSticker(sticker);
});

validationCube3dElement.addEventListener("keydown", (event) => {
  if (event.key !== "Enter" && event.key !== " ") return;
  const sticker = event.target.closest(".sticker[role='button']");
  if (!sticker) return;
  event.preventDefault();
  paintValidationSticker(sticker);
});

document.querySelectorAll(".validation-swatch").forEach((button) => {
  button.addEventListener("click", () => selectValidationColor(button.dataset.faceletColor));
});
selectValidationColor("U");

// Feedback corto y consistente en todos los botones de la interfaz.
document.addEventListener("click", (event) => {
  const button = event.target.closest("button");
  if (!button || button.disabled || reducedMotion.matches) return;
  button.classList.remove("button-feedback");
  void button.offsetWidth;
  button.classList.add("button-feedback");
  button.addEventListener("animationend", () => button.classList.remove("button-feedback"), { once: true });
});

// Eventos de los controles principales.
scrambleButton.addEventListener("click", scramble);
resetButton.addEventListener("click", reset);
solveButton.addEventListener("click", solve);
compareButton.addEventListener("click", compare);
benchmarkButton.addEventListener("click", benchmark);

navSolveButton.addEventListener("click", () => showPanel("solve"));
navCompareButton.addEventListener("click", () => showPanel("compare"));
navBenchmarkButton.addEventListener("click", () => showPanel("benchmark"));
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