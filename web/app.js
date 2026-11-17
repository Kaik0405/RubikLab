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
const compareScrambleButton = document.querySelector("#compareScrambleButton");
const compareScramblePreview = document.querySelector("#compareScramblePreview");
const compareScrambleCount = document.querySelector("#compareScrambleCount");
const compareSendToSolveButton = document.querySelector("#compareSendToSolveButton");
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
const scrambleInput = document.querySelector("#scrambleInput");
const loadScrambleButton = document.querySelector("#loadScrambleButton");
const solvePlayback = document.querySelector("#solvePlayback");
const solvePlaybackPhase = document.querySelector("#solvePlaybackPhase");
const solveStepCounter = document.querySelector("#solveStepCounter");
const solvePrevButton = document.querySelector("#solvePrevButton");
const solvePlayButton = document.querySelector("#solvePlayButton");
const solveNextButton = document.querySelector("#solveNextButton");
const solveProgressRange = document.querySelector("#solveProgressRange");
const solveCurrentMove = document.querySelector("#solveCurrentMove");
const copySolutionButton = document.querySelector("#copySolutionButton");
const faceletsInput = document.querySelector("#faceletsInput");
const loadFaceletsButton = document.querySelector("#loadFaceletsButton");
const benchmarkCountControl = document.querySelector("#benchmarkCount");
const benchmarkLengthControl = document.querySelector("#benchmarkLength");
const benchmarkVisualPlayback = document.querySelector("#benchmarkVisualPlayback");
const validationUndoButton = document.querySelector("#validationUndoButton");
const validationRedoButton = document.querySelector("#validationRedoButton");
const copyFaceletsButton = document.querySelector("#copyFaceletsButton");
const validationInventory = document.querySelector("#validationInventory");
const navSolveButton = document.querySelector("#navSolveButton");
const navCompareButton = document.querySelector("#navCompareButton");
const navBenchmarkButton = document.querySelector("#navBenchmarkButton");

const comparison = {
  thistle: {
    cube2d: document.querySelector("#thistleCube"),
    cube3d: document.querySelector("#thistleCube3d"),
    stage: document.querySelector("#thistleStage"),
    count: document.querySelector("#thistleCount"),
    total: document.querySelector("#thistleTotal"),
    steps: document.querySelector("#thistleSteps"),
    notation: document.querySelector("#thistleNotation"),
    card: document.querySelector("#compareThistle")
  },
  cfop: {
    cube2d: document.querySelector("#cfopCube"),
    cube3d: document.querySelector("#cfopCube3d"),
    stage: document.querySelector("#cfopStage"),
    count: document.querySelector("#cfopCount"),
    total: document.querySelector("#cfopTotal"),
    steps: document.querySelector("#cfopSteps"),
    notation: document.querySelector("#cfopNotation"),
    card: document.querySelector("#compareCfop")
  }
};

let userMoves = [];
let solutionMoves = [];
let doubleMovePending = false;
let requestInProgress = false;
let validationFacelets = [];
let selectedValidationColor = "U";
let validationHistory = [];
let validationHistoryIndex = -1;
let compareScrambleMoves = [];
let solveBaseMoves = [];
let solveTimeline = [];
let solvePhaseRanges = [];
let solveCursor = 0;
let solvePlaybackToken = 0;
let solveIsPlaying = false;
let benchmarkRows = [];
let benchmarkSelectedIndex = -1;
let benchmarkSelectedMethod = "thistle";
let comparisonSequences = { thistle: [], cfop: [] };

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

// Preferencia de accesibilidad para las animaciones de interfaz.
// Los cubos de Resolver y Comparar mantienen fija la cámara durante la reproducción.
const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

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
    throw new Error("No se pudo obtener el estado del cubo.");
  }

  return response.json();
}

function comparisonNotation(moves) {
  return moves.length ? moves.map(toNotation).join(" ") : "—";
}

function renderComparisonScramble() {
  if (!compareScrambleMoves.length) {
    compareScrambleCount.textContent = "Sin mezcla";
    if (compareSendToSolveButton) compareSendToSolveButton.disabled = true;
    compareScramblePreview.textContent = "Genera una mezcla para comenzar. No se modificará el cubo de Resolver.";
    return;
  }

  compareScrambleCount.textContent = `${compareScrambleMoves.length} movimientos`;
  if (compareSendToSolveButton) compareSendToSolveButton.disabled = false;
  compareScramblePreview.classList.remove("is-error");
  compareScramblePreview.textContent = comparisonNotation(compareScrambleMoves);
}

async function requestComparisonScramble() {
  const response = await fetch("/api/scramble?n=25");
  const result = await response.json();
  if (!response.ok) {
    throw new Error(result.error || "No se pudo generar la mezcla de comparación.");
  }

  if (!Array.isArray(result.moves) || result.moves.length === 0) {
    throw new Error("El servidor no devolvió una mezcla válida.");
  }

  compareScrambleMoves = result.moves.slice();
  const initialState = await fetchStateForMoves(compareScrambleMoves);
  Object.values(comparison).forEach((view) => {
    renderFacelets(view.cube2d, initialState.facelets);
    renderFacelets(view.cube3d, initialState.facelets);
    view.count.textContent = "0";
    view.total.textContent = "—";
    view.stage.textContent = "Mezcla preparada";
    view.steps.innerHTML = '<p class="compare-detail-empty">Pulsa «Iniciar comparación» para ejecutar las fases.</p>';
    view.notation.textContent = "—";
    view.card.classList.remove("finished", "completed", "winner");
  });

  renderComparisonScramble();
  document.querySelector("#compareSummary").innerHTML = `
    <div class="empty-state compact-empty">
      <strong>Mezcla lista para comparar</strong>
      <p>Los dos métodos resolverán estos ${compareScrambleMoves.length} movimientos iniciales, sin alterar el cubo de Resolver.</p>
    </div>`;
}

async function generateComparisonScramble() {
  if (requestInProgress) return;
  setBusy(true);
  compareScrambleButton.textContent = "Generando…";
  try {
    await requestComparisonScramble();
  } catch (error) {
    compareScramblePreview.textContent = error.message;
    compareScramblePreview.classList.add("is-error");
  } finally {
    compareScrambleButton.innerHTML = '<span>⤨</span> Generar mezcla';
    setBusy(false);
  }
}

function renderComparisonSteps(method, result) {
  const view = comparison[method];
  const steps = Array.isArray(result.steps) ? result.steps : [];
  const allMoves = steps.flatMap((step) => step.moves || []);
  view.total.textContent = String(result.total_moves ?? allMoves.length);
  view.notation.textContent = comparisonNotation(allMoves);
  let moveOffset = 0;
  view.steps.innerHTML = steps.map((step, index) => {
    const moves = step.moves || [];
    const title = step.stage || step.name || `Fase ${index + 1}`;
    const chips = moves.map((move, moveIndex) => {
      const absoluteIndex = moveOffset + moveIndex;
      return `<button class="compare-step-move" type="button" data-comparison-method="${method}" data-comparison-jump="${absoluteIndex + 1}" title="Inspeccionar después de ${toNotation(move)}">${toNotation(move)}</button>`;
    }).join("");
    moveOffset += moves.length;
    return `
      <article class="compare-step" data-compare-step="${index}">
        <div class="compare-step-top"><span class="compare-step-index">${String(index + 1).padStart(2, "0")}</span><strong>${escapeHTML(title)}</strong><small>${moves.length} mov.</small></div>
        <p class="compare-step-rule">${escapeHTML(step.rule || "Etapa del algoritmo")}</p>
        <div class="compare-step-moves">${chips || '<span class="phase-no-moves">Sin movimientos</span>'}</div>
        <div class="compare-step-metrics"><span>${Number(step.nodes || 0).toLocaleString("es-ES")} nodos</span><span>${Number(step.seconds || 0).toFixed(4)} s</span></div>
      </article>`;
  }).join("") || '<p class="compare-detail-empty">El solver no devolvió fases.</p>';
  const notationCard = view.notation.closest(".compare-notation");
  if (notationCard && !notationCard.querySelector(".copy-compare-notation")) {
    const copyButton = document.createElement("button");
    copyButton.type = "button";
    copyButton.className = "utility-button copy-compare-notation";
    copyButton.textContent = "Copiar notación";
    copyButton.addEventListener("click", async () => {
      try {
        await navigator.clipboard.writeText(view.notation.textContent);
        copyButton.textContent = "Copiado ✓";
      } catch {
        copyButton.textContent = "No disponible";
      }
    });
    notationCard.appendChild(copyButton);
  }
}

async function animateComparison(method, result) {
  const view = comparison[method];
  const steps = Array.isArray(result.steps) ? result.steps : [];
  const moves = [];
  const initialState = await fetchStateForMoves(compareScrambleMoves);

  renderFacelets(view.cube2d, initialState.facelets);
  renderFacelets(view.cube3d, initialState.facelets);
  renderComparisonSteps(method, result);
  view.count.textContent = "0";

  for (let stepIndex = 0; stepIndex < steps.length; stepIndex += 1) {
    const step = steps[stepIndex];
    const stepCard = view.steps.querySelector(`[data-compare-step="${stepIndex}"]`);
    view.steps.querySelectorAll(".compare-step").forEach((item) => item.classList.remove("is-active", "is-complete"));
    stepCard?.classList.add("is-active");
    view.stage.textContent = `${step.stage || step.name}: ${step.rule || "Ejecutando fase"}`;

    for (const move of step.moves || []) {
      moves.push(move);
      const state = await fetchStateForMoves(compareScrambleMoves.concat(moves));

      // La cámara queda fija: solo cambia el estado de las pegatinas.
      renderFacelets(view.cube2d, state.facelets);
      renderFacelets(view.cube3d, state.facelets);
      view.count.textContent = String(moves.length);

      await new Promise((resolve) => setTimeout(resolve, Math.max(55, Number(intervalControl.value) || 180)));
    }

    stepCard?.classList.remove("is-active");
    stepCard?.classList.add("is-complete");
  }

  view.stage.textContent = "Terminado";
  view.card.classList.add("completed");
}

function renderComparisonSummary(results) {
  const summary = document.querySelector("#compareSummary");
  const fastest = Number(results.thistle.seconds) <= Number(results.cfop.seconds) ? "thistle" : "cfop";

  summary.innerHTML = `
    <table class="compare-summary-table">
      <thead>
        <tr><th>Método</th><th>Movimientos</th><th>Nodos</th><th>Segundos</th></tr>
      </thead>
      <tbody>
        ${["thistle", "cfop"].map((method) => `
          <tr>
            <td>${method === "thistle" ? "Thistlethwaite" : "CFOP"}</td>
            <td>${results[method].total_moves}</td>
            <td>${Number(results[method].nodes || 0).toLocaleString("es-ES")}</td>
            <td>${Number(results[method].seconds).toFixed(4)}</td>
          </tr>`).join("")}
      </tbody>
    </table>
    <div class="compare-chart motion-chart-card">
      <div class="motion-chart-heading"><div><span class="benchmark-eyebrow">COMPARACIÓN DIRECTA</span><strong>Movimientos y tiempo</strong></div><div class="motion-chart-legend"><span class="legend-thistle">Thistle</span><span class="legend-cfop">CFOP</span></div></div>
      ${["thistle", "cfop"].map((method) => {
        const item = results[method];
        const maxMoves = Math.max(results.thistle.total_moves, results.cfop.total_moves, 1);
        return `<div class="compare-chart-row"><span>${method === "thistle" ? "Thistlethwaite" : "CFOP"}</span><div class="compare-chart-track"><i class="${method}" style="--target-width:${(item.total_moves / maxMoves) * 100}%"></i></div><strong>${item.total_moves} mov.</strong><small>${Number(item.seconds).toFixed(4)} s</small></div>`;
      }).join("")}
    </div>
    <p class="compare-winner-line">Menor tiempo de CPU: <strong>${fastest === "thistle" ? "Thistlethwaite" : "CFOP"}</strong></p>`;

  comparison[fastest].card.classList.add("winner");
}

async function compare() {
  if (requestInProgress) return;

  setBusy(true);
  showPanel("compare");
  document.querySelector("#compareSummary").textContent = "Preparando la comparación…";

  Object.values(comparison).forEach((view) => {
    view.card.classList.remove("finished", "completed", "winner");
    view.stage.textContent = "Preparando…";
    view.count.textContent = "0";
  });

  try {
    // Si el usuario no generó la mezcla manualmente, se crea aquí de forma autónoma.
    if (!compareScrambleMoves.length) await requestComparisonScramble();

    const query = encodeURIComponent(compareScrambleMoves.join(","));
    const response = await fetch(`/api/compare?moves=${query}`);
    const result = await response.json();
    if (!response.ok) throw new Error(responseError(result, response.status));
    if (!result.thistle || !result.cfop) throw new Error("La respuesta de comparación está incompleta.");

    comparisonSequences = {
      thistle: (result.thistle.steps || []).flatMap((step) => step.moves || []),
      cfop: (result.cfop.steps || []).flatMap((step) => step.moves || [])
    };
    await Promise.all([
      animateComparison("thistle", result.thistle),
      animateComparison("cfop", result.cfop)
    ]);

    renderComparisonSummary(result);
  } catch (error) {
    document.querySelector("#compareSummary").textContent = error.message;
  } finally {
    setBusy(false);
  }
}

comparePanel.addEventListener("click", async (event) => {
  const chip = event.target.closest("[data-comparison-jump]");
  if (!chip || requestInProgress) return;
  const method = chip.dataset.comparisonMethod;
  const count = Number(chip.dataset.comparisonJump);
  const prefix = (comparisonSequences[method] || []).slice(0, count);
  try {
    const state = await fetchStateForMoves(compareScrambleMoves.concat(prefix));
    const view = comparison[method];
    renderFacelets(view.cube2d, state.facelets);
    renderFacelets(view.cube3d, state.facelets);
    view.count.textContent = String(count);
    view.stage.textContent = `Inspección · movimiento ${count}`;
    view.steps.querySelectorAll(".compare-step").forEach((step) => step.classList.remove("is-active"));
    chip.closest(".compare-step")?.classList.add("is-active");
  } catch (error) {
    document.querySelector("#compareSummary").textContent = error.message;
  }
});

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
            <span>Selecciona una mezcla para inspeccionar ambas soluciones</span>
          </div>
          <div class="benchmark-history" id="benchmarkHistory">
            <span class="benchmark-empty">Esperando la primera prueba...</span>
          </div>
        </div>
        <section class="benchmark-inspector" id="benchmarkInspector">
          <header class="benchmark-inspector-header"><div><span class="benchmark-eyebrow">SOLUTION EXPLORER</span><h3 id="benchmarkDetailTitle">Explorador de soluciones</h3></div><span id="benchmarkDetailIndex" class="benchmark-results-count">Sin selección</span></header>
          <div class="benchmark-detail-scramble"><span>SCRAMBLE DE LA PRUEBA</span><p id="benchmarkDetailScramble">Selecciona una prueba del historial.</p><div class="benchmark-detail-actions"><button id="benchmarkSendToSolveButton" class="utility-button" type="button" disabled>Enviar mezcla</button><button id="benchmarkReplaySolutionButton" class="utility-button" type="button" disabled>Reproducir esta solución ▶</button></div></div>
          <div class="benchmark-detail-tabs"><button class="benchmark-method-tab is-active" type="button" data-benchmark-method="thistle">Thistlethwaite</button><button class="benchmark-method-tab" type="button" data-benchmark-method="cfop">CFOP</button></div>
          <div id="benchmarkDetailContent" class="benchmark-detail-content"><p class="benchmark-empty">Aquí verás las fases, la notación completa y las métricas de cada método.</p></div>
        </section>
      </div>
    </section>
  `;

  const thistleCube = document.querySelector("#benchmarkThistleCube");
  const cfopCube = document.querySelector("#benchmarkCfopCube");
  createCube(thistleCube);
  createCube(cfopCube);

  const history = document.querySelector("#benchmarkHistory");
  history.addEventListener("click", (event) => {
    const row = event.target.closest("[data-benchmark-index]");
    if (!row) return;
    benchmarkSelectedIndex = Number(row.dataset.benchmarkIndex);
    benchmarkRenderHistory(benchmarkRows);
    benchmarkRenderDetail(benchmarkRows, benchmarkSelectedIndex, benchmarkSelectedMethod);
  });
  document.querySelector("#benchmarkInspector").addEventListener("click", (event) => {
    const tab = event.target.closest("[data-benchmark-method]");
    if (!tab) return;
    benchmarkSelectedMethod = tab.dataset.benchmarkMethod;
    benchmarkRenderDetail(benchmarkRows, benchmarkSelectedIndex, benchmarkSelectedMethod);
  });
  document.querySelector("#benchmarkSendToSolveButton").addEventListener("click", async () => {
    const row = benchmarkRows[benchmarkSelectedIndex];
    if (!row) return;
    try {
      await loadScrambleIntoResolver(row.scrambleMoves, `Mezcla ${benchmarkSelectedIndex + 1} del benchmark`);
    } catch (error) {
      benchmarkStatus.textContent = error.message;
    }
  });
  document.querySelector("#benchmarkReplaySolutionButton").addEventListener("click", async () => {
    const row = benchmarkRows[benchmarkSelectedIndex];
    if (!row) return;
    try {
      await openBenchmarkSolutionInResolver(row, benchmarkSelectedMethod, benchmarkSelectedIndex);
    } catch (error) {
      benchmarkStatus.textContent = error.message;
    }
  });

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
  if (!history) return;
  history.innerHTML = rows.map((row, index) => {
    const t = row.thistle.total_moves;
    const c = row.cfop.total_moves;
    const max = Math.max(t, c, 1);
    const selected = index === benchmarkSelectedIndex;
    return `
      <button class="benchmark-history-row ${selected ? "is-selected" : ""}" type="button" data-benchmark-index="${index}" aria-pressed="${selected}">
        <span class="benchmark-history-index">${String(index + 1).padStart(2, "0")}</span>
        <span class="benchmark-history-bars">
          <span class="benchmark-history-bar-line"><span>TH</span><i><b style="width:${(t / max) * 100}%"></b></i><strong>${t}</strong></span>
          <span class="benchmark-history-bar-line"><span>CF</span><i><b style="width:${(c / max) * 100}%"></b></i><strong>${c}</strong></span>
        </span>
        <span class="benchmark-history-open">Ver solución →</span>
      </button>
    `;
  }).join("") || '<span class="benchmark-empty">Esperando la primera prueba...</span>';
}

function benchmarkRenderDetail(rows, index, method) {
  const title = document.querySelector("#benchmarkDetailTitle");
  const detailIndex = document.querySelector("#benchmarkDetailIndex");
  const scramble = document.querySelector("#benchmarkDetailScramble");
  const content = document.querySelector("#benchmarkDetailContent");
  const sendButton = document.querySelector("#benchmarkSendToSolveButton");
  const replayButton = document.querySelector("#benchmarkReplaySolutionButton");
  if (!title || !content) return;
  const row = rows[index];
  document.querySelectorAll(".benchmark-method-tab").forEach((tab) => {
    const selected = tab.dataset.benchmarkMethod === method;
    tab.classList.toggle("is-active", selected);
    tab.setAttribute("aria-pressed", String(selected));
  });
  if (!row) {
    title.textContent = "Explorador de soluciones";
    detailIndex.textContent = "Sin selección";
    scramble.textContent = "Selecciona una prueba del historial.";
    content.innerHTML = '<p class="benchmark-empty">Aquí verás las fases, la notación completa y las métricas de cada método.</p>';
    sendButton.disabled = true;
    if (replayButton) replayButton.disabled = true;
    return;
  }

  const result = row[method];
  const name = method === "thistle" ? "Thistlethwaite" : "CFOP";
  const moves = (result.steps || []).flatMap((step) => step.moves || []);
  title.textContent = `${name} · Solución de la prueba ${index + 1}`;
  detailIndex.textContent = `PRUEBA ${String(index + 1).padStart(2, "0")} / ${rows.length}`;
  scramble.textContent = row.scrambleMoves.map(toNotation).join(" ");
  sendButton.disabled = false;
  if (replayButton) replayButton.disabled = false;
  content.innerHTML = `
    <div class="benchmark-detail-metrics">
      <div><strong>${result.total_moves}</strong><span>movimientos</span></div>
      <div><strong>${Number(result.nodes || 0).toLocaleString("es-ES")}</strong><span>nodos</span></div>
      <div><strong>${Number(result.seconds || 0).toFixed(4)} s</strong><span>tiempo CPU</span></div>
    </div>
    <div class="benchmark-detail-phase-list">
      ${(result.steps || []).map((step, phaseIndex) => `
        <article class="benchmark-detail-phase">
          <div class="benchmark-detail-phase-head"><span>${String(phaseIndex + 1).padStart(2, "0")}</span><strong>${escapeHTML(step.stage || step.name || `Fase ${phaseIndex + 1}`)}</strong><small>${(step.moves || []).length} mov.</small></div>
          <p>${escapeHTML(step.rule || "Etapa del algoritmo")}</p>
          <div class="benchmark-detail-moves">${(step.moves || []).map((move) => `<span>${toNotation(move)}</span>`).join("") || '<em>Sin movimientos</em>'}</div>
          <small class="benchmark-detail-stats">${Number(step.nodes || 0).toLocaleString("es-ES")} nodos · ${Number(step.seconds || 0).toFixed(4)} s</small>
        </article>`).join("")}
    </div>
    <div class="benchmark-detail-notation"><span>NOTACIÓN COMPLETA</span><p>${comparisonNotation(moves)}</p><button id="benchmarkCopyNotationButton" class="utility-button" type="button">Copiar notación</button></div>
  `;
  document.querySelector("#benchmarkCopyNotationButton")?.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(comparisonNotation(moves));
      document.querySelector("#benchmarkCopyNotationButton").textContent = "Copiado ✓";
    } catch {
      document.querySelector("#benchmarkCopyNotationButton").textContent = "No disponible";
    }
  });
}

async function animateBenchmarkMethod(method, result, scrambleMoves, view, animateVisually = true) {
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

  if (!animateVisually) {
    const finalMoves = (result.steps || []).flatMap((step) => step.moves || []);
    const finalState = await fetchStateForMoves(scrambleMoves.concat(finalMoves));
    renderFacelets(view.cube, finalState.facelets);
    view.count.textContent = String(finalMoves.length);
    view.moves.textContent = finalMoves.map(toNotation).join(" ") || "—";
    view.stage.textContent = "Cubo resuelto";
    view.state.textContent = "Completado";
    view.bar.style.width = "100%";
    view.percent.textContent = "100%";
    view.card.classList.add("completed");
    return;
  }

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
    total_moves: Number(result.total_moves) || (result.steps || []).reduce((sum, step) => sum + (step.moves || []).length, 0),
    nodes: Number(result.nodes) || 0,
    seconds: Number(result.seconds) || 0,
    steps: Array.isArray(result.steps) ? result.steps : []
  };
}

async function benchmark() {
  if (requestInProgress) return;

  setBusy(true);
  showPanel("benchmark");
  benchmarkStatus.textContent = "Preparando el benchmark…";
  benchmarkTable.innerHTML = "";
  benchmarkRows = [];
  benchmarkSelectedIndex = -1;
  const totalTests = Math.max(1, Math.min(30, Number(benchmarkCountControl?.value) || 10));
  const scrambleLength = Math.max(5, Math.min(40, Number(benchmarkLengthControl?.value) || 25));
  const animateVisually = Boolean(benchmarkVisualPlayback?.checked);
  const benchmarkTag = benchmarkPanel.querySelector(".benchmark-tag");
  if (benchmarkTag) benchmarkTag.textContent = `${totalTests} pruebas · mezclas de ${scrambleLength} movimientos`;
  const benchmarkConfig = benchmarkPanel.querySelector(".benchmark-launch-card strong");
  if (benchmarkConfig) benchmarkConfig.textContent = `${totalTests} mezclas · ${scrambleLength} movimientos`;

  const rows = [];
  const views = createBenchmarkView();
  try {
    for (let index = 0; index < totalTests; index += 1) {
      benchmarkSetProgress(index, totalTests, `Generando mezcla ${index + 1} de ${totalTests}…`);
      const scrambleResponse = await fetch(`/api/scramble?n=${scrambleLength}`);
      const scrambleResult = await scrambleResponse.json();
      if (!scrambleResponse.ok) throw new Error(scrambleResult.error || "No se pudo generar la mezcla.");
      const scrambleMoves = scrambleResult.moves;
      if (!Array.isArray(scrambleMoves) || !scrambleMoves.length) throw new Error("El backend devolvió una mezcla vacía.");

      const query = encodeURIComponent(scrambleMoves.join(","));
      const compareResponse = await fetch(`/api/compare?moves=${query}`);
      const compareResult = await compareResponse.json();
      if (!compareResponse.ok) throw new Error(responseError(compareResult, compareResponse.status));
      if (!compareResult.thistle || !compareResult.cfop) throw new Error("El backend no devolvió ambos métodos para el benchmark.");

      const thistle = benchmarkNormalizeResult(compareResult.thistle);
      const cfop = benchmarkNormalizeResult(compareResult.cfop);
      views.thistle.scramble.textContent = scrambleMoves.map(toNotation).join(" ");
      views.cfop.scramble.textContent = scrambleMoves.map(toNotation).join(" ");
      benchmarkSetProgress(index, totalTests,
        animateVisually
          ? `Prueba ${index + 1}: reproduciendo las dos soluciones.`
          : `Prueba ${index + 1}: calculando y registrando métricas.`);

      await Promise.all([
        animateBenchmarkMethod("thistle", thistle, scrambleMoves, views.thistle, animateVisually),
        animateBenchmarkMethod("cfop", cfop, scrambleMoves, views.cfop, animateVisually)
      ]);

      rows.push({ scrambleMoves: scrambleMoves.slice(), thistle, cfop });
      benchmarkRows = rows;
      benchmarkSelectedIndex = rows.length - 1;
      benchmarkSelectedMethod = "thistle";
      benchmarkRenderMetrics(rows);
      benchmarkRenderHistory(rows);
      benchmarkRenderDetail(rows, benchmarkSelectedIndex, benchmarkSelectedMethod);
      benchmarkSetProgress(index + 1, totalTests,
        index + 1 === totalTests
          ? "Todas las mezclas se han resuelto."
          : `Prueba ${index + 1} completada. Preparando la siguiente…`);
    }

    const progressBar = document.querySelector("#benchmarkProgressBar");
    if (progressBar) progressBar.style.width = "100%";
    const progressTitle = document.querySelector("#benchmarkProgressTitle");
    if (progressTitle) progressTitle.textContent = "Benchmark completado";
    benchmarkStatus.textContent = `Benchmark completado: ${totalTests} mezclas de ${scrambleLength} movimientos. Selecciona cualquier prueba del historial para estudiar sus soluciones.`;
  } catch (error) {
    benchmarkStatus.textContent = error.message;
    const title = document.querySelector("#benchmarkProgressTitle");
    if (title) title.textContent = "Benchmark interrumpido";
    benchmarkRows = rows;
    benchmarkRenderHistory(rows);
    benchmarkRenderDetail(rows, benchmarkSelectedIndex, benchmarkSelectedMethod);
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

function updateValidationHistoryControls() {
  if (validationUndoButton) validationUndoButton.disabled = validationHistoryIndex <= 0;
  if (validationRedoButton) validationRedoButton.disabled = validationHistoryIndex < 0 || validationHistoryIndex >= validationHistory.length - 1;
}

function updateValidationInventory() {
  if (!validationInventory) return;
  const faces = ["U", "R", "F", "D", "L", "B"];
  const names = { U: "Blanco", R: "Rojo", F: "Verde", D: "Amarillo", L: "Naranja", B: "Azul" };
  const counts = Object.fromEntries(faces.map((face) => [face, validationFacelets.filter((value) => value === face).length]));
  const isBalanced = faces.every((face) => counts[face] === 9);
  validationInventory.innerHTML = `
    <div class="validation-inventory-head"><strong>Inventario de colores</strong><span class="${isBalanced ? "inventory-balanced" : "inventory-unbalanced"}">${isBalanced ? "54 / 54 correctos" : "Requiere 9 por color"}</span></div>
    <div class="validation-inventory-grid">${faces.map((face) => `<div class="inventory-color inventory-${face.toLowerCase()}"><i></i><span>${names[face]}</span><strong>${counts[face]}/9</strong></div>`).join("")}</div>`;
}

function setValidationFacelets(facelets, options = {}) {
  const nextFacelets = Array.from(facelets || []);
  if (nextFacelets.length !== 54) return;
  if (options.record !== false) {
    const current = validationHistory[validationHistoryIndex];
    if (!current || current.join("") !== nextFacelets.join("")) {
      validationHistory = validationHistory.slice(0, validationHistoryIndex + 1);
      validationHistory.push(nextFacelets.slice());
      if (validationHistory.length > 100) validationHistory.shift();
      validationHistoryIndex = validationHistory.length - 1;
    }
  }
  validationFacelets = nextFacelets;
  renderFacelets(validationCube, validationFacelets);
  renderFacelets(validationCube3dElement, validationFacelets);
  updateValidationInventory();
  updateValidationHistoryControls();
}

function undoValidationEdit() {
  if (validationHistoryIndex <= 0) return;
  validationHistoryIndex -= 1;
  setValidationFacelets(validationHistory[validationHistoryIndex], { record: false });
  validationResult.textContent = "";
  validationResult.className = "validation-result";
}

function redoValidationEdit() {
  if (validationHistoryIndex >= validationHistory.length - 1) return;
  validationHistoryIndex += 1;
  setValidationFacelets(validationHistory[validationHistoryIndex], { record: false });
  validationResult.textContent = "";
  validationResult.className = "validation-result";
}

async function copyValidationFacelets() {
  const value = validationFacelets.join("");
  try {
    await navigator.clipboard.writeText(value);
    validationResult.className = "validation-result valid";
    validationResult.textContent = "Estado de 54 facelets copiado al portapapeles.";
  } catch {
    validationResult.className = "validation-result";
    validationResult.textContent = value;
  }
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

function loadFaceletsFromInput() {
  const value = String(faceletsInput.value || "").replace(/\s+/g, "").toUpperCase();
  if (value.length !== 54 || /[^URFDLB]/.test(value)) {
    validationResult.className = "validation-result invalid";
    validationResult.textContent = "Introduce exactamente 54 letras usando U, R, F, D, L y B.";
    return;
  }
  setValidationFacelets(value.split(""));
  validationResult.className = "validation-result";
  validationResult.textContent = "Estado importado. Comprueba su legalidad.";
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

function parseScrambleNotation(raw) {
  const normalized = String(raw || "").trim();
  if (!normalized) throw new Error("Escribe una secuencia de movimientos.");
  const tokens = normalized.split(/[\s,]+/).filter(Boolean);
  const moves = [];
  for (const token of tokens) {
    const match = token.match(/^([URFDLBurfdlb])([2']?)$/);
    if (!match) throw new Error(`Notación no reconocida: ${token}`);
    const face = match[1].toLowerCase();
    const suffix = match[2] === "'" ? "i" : match[2];
    moves.push(`${face}${suffix}`);
  }
  return moves;
}

async function loadScrambleIntoResolver(moves, sourceLabel = "Scramble cargado") {
  if (!Array.isArray(moves) || moves.length === 0) throw new Error("La mezcla no contiene movimientos.");
  stopSolvePlayback();
  clearSolution();
  userMoves = moves.slice();
  showPanel("solve");
  setBusy(true);
  try {
    const state = await fetchStateForMoves(userMoves);
    renderFacelets(cubeElement, state.facelets);
    renderFacelets(mainCube3dElement, state.facelets);
    setStatus(state.legal);
    renderMoves();
    updateStatus(`${sourceLabel} · ${userMoves.length} movimientos`);
    if (scrambleInput) scrambleInput.value = userMoves.map(toNotation).join(" ");
  } catch (error) {
    updateStatus(error.message, "status error");
    throw error;
  } finally {
    setBusy(false);
  }
}

async function openBenchmarkSolutionInResolver(row, method, index) {
  stopSolvePlayback();
  clearSolution();
  userMoves = row.scrambleMoves.slice();
  solveBaseMoves = userMoves.slice();
  methodSelect.value = method;
  showPanel("solve");
  setBusy(true);
  try {
    const state = await fetchStateForMoves(solveBaseMoves);
    renderFacelets(cubeElement, state.facelets);
    renderFacelets(mainCube3dElement, state.facelets);
    setStatus(state.legal);
    renderMoves();
    const result = row[method];
    await renderSolution(result.steps || [], solveBaseMoves);
    solveSummary.textContent = `${method === "thistle" ? "Thistlethwaite" : "CFOP"} · Prueba ${index + 1} · ${result.total_moves} movimientos`;
    setBusy(false);
    playSolution();
  } finally {
    if (requestInProgress) setBusy(false);
  }
}

async function loadScrambleFromInput() {
  if (requestInProgress) return;
  try {
    const moves = parseScrambleNotation(scrambleInput.value);
    await loadScrambleIntoResolver(moves, "Mezcla importada");
  } catch (error) {
    updateStatus(error.message, "status error");
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

function stopSolvePlayback() {
  solvePlaybackToken += 1;
  solveIsPlaying = false;
  updateSolvePlaybackUI();
}

function clearSolution() {
  stopSolvePlayback();
  solutionMoves = [];
  solveBaseMoves = [];
  solveTimeline = [];
  solvePhaseRanges = [];
  solveCursor = 0;

  phaseList.innerHTML = "";
  solveSummary.textContent = "";
  solutionMovesElement.textContent = "—";
  if (solvePlayback) solvePlayback.hidden = true;
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
  if (loadScrambleButton) loadScrambleButton.disabled = isBusy;
  compareButton.disabled = isBusy;
  if (compareScrambleButton) compareScrambleButton.disabled = isBusy;
  if (compareSendToSolveButton) compareSendToSolveButton.disabled = isBusy || compareScrambleMoves.length === 0;
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
  if (name !== "solve" && solveIsPlaying) stopSolvePlayback();
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
  stopSolvePlayback();
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
  stopSolvePlayback();
  setBusy(true);
  try {
    // Reinicio instantáneo de estado: la orientación de la cámara permanece fija.
    userMoves = [];
    solutionMoves = [];
    clearSolution();
    await updateState(false);
  } finally {
    setBusy(false);
  }
}

function escapeHTML(value) {
  return String(value ?? "").replace(/[&<>"']/g, (character) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  })[character]);
}

function isLastLayerPhase(phase) {
  const name = `${phase.stage || phase.name || ""} ${phase.rule || ""}`;
  return /\b(OLL|PLL)\b/i.test(name);
}

function renderLastLayerPattern(facelets, phase) {
  const stageName = phase.stage || phase.name || "Última capa";
  const type = /\bPLL\b/i.test(stageName) ? "PLL" : "OLL";
  const caseMatch = stageName.match(/\b(?:OLL|PLL)\s*(?:#|n[.º°]?\s*)?(\d+)/i);
  const caseName = caseMatch ? `${type} ${caseMatch[1]}` : stageName;
  const colors = { U: "#f2f4f8", R: "#e34c5b", F: "#31b978", D: "#f0ce45", L: "#f28b42", B: "#4284df" };
  const labelColor = { U: "blanco", R: "rojo", F: "verde", D: "amarillo", L: "naranja", B: "azul" };
  const rows = [
    { label: "U", indices: [0, 1, 2, 3, 4, 5, 6, 7, 8], x: 66, y: 12, cols: 3 },
    { label: "L", indices: [36, 37, 38], x: 8, y: 58, cols: 3 },
    { label: "F", indices: [18, 19, 20], x: 66, y: 92, cols: 3 },
    { label: "R", indices: [9, 10, 11], x: 124, y: 58, cols: 3 },
    { label: "B", indices: [45, 46, 47], x: 66, y: 126, cols: 3 }
  ];
  const cells = rows.map((row) => {
    const cellSize = row.label === "U" ? 20 : 15;
    const gap = 2;
    return row.indices.map((faceletIndex, cellIndex) => {
      const color = facelets[faceletIndex] || "U";
      const col = row.label === "U" ? cellIndex % 3 : cellIndex;
      const x = row.x + col * (cellSize + gap);
      const y = row.label === "U" ? row.y + Math.floor(cellIndex / 3) * (cellSize + gap) : row.y;
      return `<rect x="${x}" y="${y}" width="${cellSize}" height="${cellSize}" rx="3" fill="${colors[color] || "#737f90"}" stroke="rgba(10,18,32,.85)" stroke-width="1.5"><title>${row.label}: ${labelColor[color] || color}</title></rect>`;
    }).join("");
  }).join("");
  const rule = phase.rule && !/^undefined$/i.test(phase.rule) ? `<p class="last-layer-rule">${escapeHTML(phase.rule)}</p>` : "";
  return `
    <div class="last-layer-case">
      <div class="last-layer-heading"><span class="last-layer-badge">${type}</span><div><strong>${escapeHTML(caseName)}</strong><small>Patrón de la última capa antes del algoritmo</small></div></div>
      <svg class="last-layer-diagram" viewBox="0 0 190 166" role="img" aria-label="Patrón de colores de las pegatinas de la última capa, con la cara U y las filas superiores laterales">
        <path d="M65 8h64v64H65z M7 55h48v22H7z M65 89h64v22H65z M123 55h48v22h-48z M65 123h64v22H65z" fill="none" stroke="rgba(147,178,222,.2)" stroke-dasharray="3 3"/>
        ${cells}
        <g fill="#6f86a7" font-size="8" font-family="ui-monospace,monospace" font-weight="700"><text x="97" y="7" text-anchor="middle">U</text><text x="30" y="50" text-anchor="middle">L</text><text x="97" y="87" text-anchor="middle">F</text><text x="147" y="50" text-anchor="middle">R</text><text x="97" y="122" text-anchor="middle">B</text></g>
      </svg>
      ${rule}
    </div>`;
}

async function renderSolution(phases, baseMoves = []) {
  solveTimeline = [];
  solvePhaseRanges = [];
  phaseList.innerHTML = "";
  const specialPatterns = [];

  phases.forEach((phase, phaseIndex) => {
    const item = document.createElement("article");
    const moves = Array.isArray(phase.moves) ? phase.moves : [];
    const start = solveTimeline.length;
    solveTimeline.push(...moves);
    const end = solveTimeline.length;
    const title = phase.stage || phase.name || `Fase ${phaseIndex + 1}`;
    const range = { phaseIndex, start, end, title, phase };
    solvePhaseRanges.push(range);
    item.className = "phase phase-expandable";
    item.dataset.phase = String(phaseIndex);
    item.innerHTML = `
      <div class="phase-title-row"><strong>${escapeHTML(title)}</strong><span>${moves.length} movimientos</span><button class="phase-copy-button" type="button" data-phase-copy="${phaseIndex}" aria-label="Copiar movimientos de ${escapeHTML(title)}">Copiar</button></div>
      <span>${escapeHTML(phase.rule || "Etapa del algoritmo")}</span>
      <div class="phase-move-list" aria-label="Movimientos de ${escapeHTML(title)}">
        ${moves.length ? moves.map((move, moveIndex) => `<button class="phase-move-chip" type="button" data-solve-jump="${start + moveIndex + 1}" title="Ir al movimiento ${toNotation(move)}">${toNotation(move)}</button>`).join("") : '<span class="phase-no-moves">Sin movimientos · fase omitida</span>'}
      </div>
      <span class="phase-stats">${Number(phase.nodes || 0).toLocaleString("es-ES")} nodos · ${Number(phase.seconds || 0).toFixed(4)} s</span>
      ${isLastLayerPhase(phase) ? `<div class="phase-case-host" data-phase-case="${phaseIndex}"><span class="phase-case-loading">Preparando patrón del caso…</span></div>` : ""}
    `;
    item.addEventListener("click", (event) => {
      if (event.target.closest("button")) return;
      navigateSolution(range.start);
    });
    phaseList.appendChild(item);
    if (isLastLayerPhase(phase)) specialPatterns.push({ phase, range, host: item.querySelector(".phase-case-host") });
  });

  solveCursor = 0;
  solutionMoves = [];
  if (solvePlayback) solvePlayback.hidden = solveTimeline.length === 0;
  if (solveProgressRange) {
    solveProgressRange.max = String(solveTimeline.length);
    solveProgressRange.value = "0";
  }
  solvePlayback?.setAttribute("aria-hidden", String(solveTimeline.length === 0));
  updateSolvePlaybackUI();
  staggerIn(phaseList, ".phase", 75);

  // OLL y PLL reciben una miniatura real derivada del estado inmediatamente
  // anterior a su algoritmo, usando el endpoint de estado del backend.
  for (const entry of specialPatterns) {
    try {
      const prefix = solveTimeline.slice(0, entry.range.start);
      const state = await fetchStateForMoves(baseMoves.concat(prefix));
      if (entry.host) entry.host.innerHTML = renderLastLayerPattern(state.facelets, entry.phase);
    } catch (error) {
      if (entry.host) entry.host.innerHTML = `<p class="phase-case-loading">No se pudo cargar el patrón del caso: ${escapeHTML(error.message)}</p>`;
    }
  }

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
      return `<div class="phase-time-row"><span>${String(index + 1).padStart(2, "0")} · ${escapeHTML(phase.stage || phase.name)}</span><i><b style="--phase-width:${width}%;--bar-delay:${index * 85}ms"></b></i><strong>${value.toFixed(4)} s</strong></div>`;
    }).join("")}</div>`;
  phaseList.insertAdjacentElement("afterend", chart);
  staggerIn(chart, ".phase-time-row", 75);
}

function phaseRangeForCursor(cursor) {
  if (!solvePhaseRanges.length) return null;
  if (cursor >= solveTimeline.length) return solvePhaseRanges[solvePhaseRanges.length - 1];
  return solvePhaseRanges.find((range) => cursor >= range.start && cursor < range.end) || solvePhaseRanges[0];
}

function setActivePhase(index) {
  phaseList.querySelectorAll(".phase").forEach((phase, phaseIndex) => {
    phase.classList.toggle("active", phaseIndex === index);
  });
}

function updateSolvePlaybackUI() {
  if (!solvePlayback) return;
  const total = solveTimeline.length;
  const range = phaseRangeForCursor(solveCursor);
  if (solveStepCounter) solveStepCounter.textContent = `${solveCursor} / ${total}`;
  if (solvePlaybackPhase) solvePlaybackPhase.textContent = range ? range.title : "Esperando solución";
  if (solveProgressRange) {
    solveProgressRange.max = String(total);
    solveProgressRange.value = String(solveCursor);
    solveProgressRange.disabled = total === 0;
  }
  if (solveCurrentMove) {
    solveCurrentMove.textContent = solveCursor === 0 ? "Estado inicial" : toNotation(solveTimeline[solveCursor - 1]);
  }
  if (solvePrevButton) solvePrevButton.disabled = total === 0 || solveCursor === 0;
  if (solveNextButton) solveNextButton.disabled = total === 0 || solveCursor >= total;
  if (copySolutionButton) copySolutionButton.disabled = total === 0;
  if (solvePlayButton) {
    solvePlayButton.disabled = total === 0;
    solvePlayButton.textContent = solveIsPlaying ? "Ⅱ" : "▶";
    solvePlayButton.setAttribute("aria-label", solveIsPlaying ? "Pausar solución" : "Reproducir solución");
  }
  setActivePhase(range ? range.phaseIndex : -1);
  phaseList.querySelectorAll(".phase").forEach((phase, index) => {
    const phaseRange = solvePhaseRanges[index];
    phase.classList.toggle("is-phase-complete", Boolean(phaseRange && solveCursor >= phaseRange.end && phaseRange.end > phaseRange.start));
  });
}

async function goToSolutionStep(step, token = solvePlaybackToken) {
  const target = Math.max(0, Math.min(solveTimeline.length, Number(step) || 0));
  const prefix = solveTimeline.slice(0, target);
  try {
    const state = await fetchStateForMoves(solveBaseMoves.concat(prefix));
    if (token !== solvePlaybackToken) return false;
    solveCursor = target;
    solutionMoves = prefix;
    renderFacelets(cubeElement, state.facelets);
    renderFacelets(mainCube3dElement, state.facelets);
    setStatus(state.legal);
    renderMoves();
    updateSolvePlaybackUI();
    if (target === solveTimeline.length) {
      solveSummary.textContent = `Resuelto en ${solveTimeline.length} movimientos`;
    } else if (target === 0) {
      solveSummary.textContent = "Estado inicial de la solución";
    } else {
      solveSummary.textContent = `Movimiento ${target} de ${solveTimeline.length}`;
    }
    return true;
  } catch (error) {
    updateStatus(error.message, "status error");
    return false;
  }
}

async function navigateSolution(step) {
  if (!solveTimeline.length) return;
  solvePlaybackToken += 1;
  solveIsPlaying = false;
  const token = solvePlaybackToken;
  updateSolvePlaybackUI();
  await goToSolutionStep(step, token);
}

async function playSolution() {
  if (!solveTimeline.length) return;
  if (solveIsPlaying) {
    stopSolvePlayback();
    return;
  }
  if (solveCursor >= solveTimeline.length) {
    await navigateSolution(0);
  }
  solveIsPlaying = true;
  const token = ++solvePlaybackToken;
  updateSolvePlaybackUI();

  while (solveIsPlaying && token === solvePlaybackToken && solveCursor < solveTimeline.length) {
    const delay = Math.max(40, Number(intervalControl.value) || 180);
    await new Promise((resolve) => setTimeout(resolve, delay));
    if (!solveIsPlaying || token !== solvePlaybackToken) break;
    const moved = await goToSolutionStep(solveCursor + 1, token);
    if (!moved) break;
  }

  if (token === solvePlaybackToken) {
    solveIsPlaying = false;
    updateSolvePlaybackUI();
  }
}

async function copySolutionNotation() {
  if (!solveTimeline.length) return;
  const notation = solveTimeline.map(toNotation).join(" ");
  try {
    await navigator.clipboard.writeText(notation);
    copySolutionButton.textContent = "Copiada ✓";
  } catch {
    copySolutionButton.textContent = "No disponible";
  }
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
  solveBaseMoves = userMoves.slice();
  setBusy(true);
  showPanel("solve");
  solveSummary.textContent = "Calculando solución…";

  try {
    const query = encodeURIComponent(solveBaseMoves.join(","));
    const response = await fetch(`/api/solve?method=${methodSelect.value}&moves=${query}`);
    const result = await response.json();
    if (!response.ok) throw new Error(responseError(result, response.status));
    if (!Array.isArray(result.steps)) throw new Error("El backend no devolvió el desglose de fases esperado.");

    await renderSolution(result.steps, solveBaseMoves);
    solveSummary.textContent = result.total_moves != null
      ? `Solución calculada · ${result.total_moves} movimientos`
      : `Solución calculada · ${solveTimeline.length} movimientos`;
    setBusy(false);

    if (solveTimeline.length) {
      // Reproduce automáticamente, pero los controles permanecen disponibles
      // para pausar, retroceder, avanzar o saltar a cualquier movimiento.
      playSolution();
    } else {
      solveSummary.textContent = "El cubo ya está resuelto; no se requieren movimientos.";
      await goToSolutionStep(0, solvePlaybackToken);
    }
  } catch (error) {
    solveSummary.textContent = error.message;
    updateStatus(error.message, "status error");
  } finally {
    if (requestInProgress) setBusy(false);
  }
}

function handleKey(event) {
  if (!navSolveButton.classList.contains("active")) return;
  const target = event.target;
  if (target && target.closest("input, textarea, select, button, a, [contenteditable='true']")) return;

  const key = event.key.toLowerCase();

  if (event.key === "ArrowLeft" && solveTimeline.length) {
    navigateSolution(solveCursor - 1);
    event.preventDefault();
    return;
  }
  if (event.key === "ArrowRight" && solveTimeline.length) {
    navigateSolution(solveCursor + 1);
    event.preventDefault();
    return;
  }
  if (event.key === "Home" && solveTimeline.length) {
    navigateSolution(0);
    event.preventDefault();
    return;
  }
  if (event.key === "End" && solveTimeline.length) {
    navigateSolution(solveTimeline.length);
    event.preventDefault();
    return;
  }
  if ((event.key === " " || event.code === "Space") && solveTimeline.length) {
    playSolution();
    event.preventDefault();
    return;
  }

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

  const next = validationFacelets.slice();
  next[index] = selectedValidationColor;
  setValidationFacelets(next);
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
loadScrambleButton.addEventListener("click", loadScrambleFromInput);
scrambleInput.addEventListener("keydown", (event) => {
  if (event.key === "Enter") loadScrambleFromInput();
});
phaseList.addEventListener("click", async (event) => {
  const copyButton = event.target.closest("button[data-phase-copy]");
  if (copyButton) {
    const range = solvePhaseRanges[Number(copyButton.dataset.phaseCopy)];
    if (!range) return;
    const notation = solveTimeline.slice(range.start, range.end).map(toNotation).join(" ");
    try {
      await navigator.clipboard.writeText(notation);
      copyButton.textContent = "Copiado ✓";
    } catch {
      copyButton.textContent = notation ? "No disponible" : "Vacía";
    }
    return;
  }
  const moveButton = event.target.closest("button[data-solve-jump]");
  if (moveButton) navigateSolution(Number(moveButton.dataset.solveJump));
});
solvePrevButton.addEventListener("click", () => navigateSolution(solveCursor - 1));
solveNextButton.addEventListener("click", () => navigateSolution(solveCursor + 1));
solvePlayButton.addEventListener("click", playSolution);
solveProgressRange.addEventListener("input", () => navigateSolution(Number(solveProgressRange.value)));
copySolutionButton.addEventListener("click", copySolutionNotation);
compareButton.addEventListener("click", compare);
compareScrambleButton.addEventListener("click", generateComparisonScramble);
compareSendToSolveButton.addEventListener("click", async () => {
  try { await loadScrambleIntoResolver(compareScrambleMoves, "Mezcla enviada desde Comparar"); }
  catch (error) { compareScramblePreview.textContent = error.message; }
});
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
loadFaceletsButton.addEventListener("click", loadFaceletsFromInput);
faceletsInput.addEventListener("keydown", (event) => { if (event.key === "Enter") loadFaceletsFromInput(); });
validationUndoButton.addEventListener("click", undoValidationEdit);
validationRedoButton.addEventListener("click", redoValidationEdit);
copyFaceletsButton.addEventListener("click", copyValidationFacelets);

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
renderComparisonScramble();

solveSummary.textContent = 'Pulsa "Resolver" para calcular.';

updateState();