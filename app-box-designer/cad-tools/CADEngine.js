/**
 * CAD Engine - Fusion 360 Style
 * Motore CAD principale che gestisce canvas, tools, oggetti e rendering
 *
 * @module CADEngine
 * @author Box Designer CAD Engine
 */

// Import tools
import { SelectTool } from './SelectTool.js';
import { MoveTool } from './MoveTool.js';
import { LineTool } from './LineTool.js';
import { RectangleTool } from './RectangleTool.js';
import { CircleTool } from './CircleTool.js';
import { TrimTool } from './TrimTool.js';
import { OffsetTool } from './OffsetTool.js';
import { FilletTool } from './FilletTool.js';
import { MirrorTool } from './MirrorTool.js';
import { RotateTool } from './RotateTool.js';
import { ScaleTool } from './ScaleTool.js';
import { LinearDimensionTool } from './LinearDimensionTool.js';
import { AngularDimensionTool } from './AngularDimensionTool.js';
import { ArcTool } from './ArcTool.js';
import { MoveCopyTool } from './MoveCopyTool.js';
import { PatternLinearTool } from './PatternLinearTool.js';
import { PatternCircularTool } from './PatternCircularTool.js';

export class CADEngine {
  /**
   * Costruttore CAD Engine
   * @param {HTMLCanvasElement} canvas - Canvas element
   */
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');

    // Oggetti CAD
    this.objects = [];

    // History per undo/redo
    this.history = [];
    this.historyIndex = -1;
    this.maxHistory = 50;

    // Tools
    this.tools = {};
    this.currentTool = null;
    this.currentToolName = null;

    // View state
    this.zoom = 1;
    this.offset = { x: 50, y: 50 };
    this.gridSize = 10; // mm
    this.showGrid = true;
    this.snapToGrid = true;

    // Snap settings
    this.snapTolerance = 5; // mm

    // Status message
    this.statusMessage = 'Ready';

    // Object under cursor (for highlighting)
    this.highlightObject = null;

    // Performance profiling
    this.enableProfiling = false;
    this.profiling = {
      lastRenderTime: 0,
      avgRenderTime: 0,
      renderCount: 0,
      maxRenderTime: 0,
      fps: 0,
      lastFrameTime: Date.now()
    };

    // Initialize tools
    this.initializeTools();

    // Setup event listeners
    this.setupEventListeners();

    // Initial render
    this.render();
  }

  /**
   * Inizializza tutti i tools
   */
  initializeTools() {
    this.tools = {
      select: new SelectTool(this),
      move: new MoveTool(this),
      line: new LineTool(this),
      rectangle: new RectangleTool(this),
      circle: new CircleTool(this),
      trim: new TrimTool(this),
      offset: new OffsetTool(this),
      fillet: new FilletTool(this),
      mirror: new MirrorTool(this),
      rotate: new RotateTool(this),
      scale: new ScaleTool(this),
      linear_dimension: new LinearDimensionTool(this),
      angular_dimension: new AngularDimensionTool(this),
      arc: new ArcTool(this),
      move_copy: new MoveCopyTool(this),
      pattern_linear: new PatternLinearTool(this),
      pattern_circular: new PatternCircularTool(this)
    };
  }

  /**
   * Setup event listeners
   */
  setupEventListeners() {
    // Mouse events
    this.canvas.addEventListener('click', (e) => this.handleClick(e));
    this.canvas.addEventListener('mousemove', (e) => this.handleMouseMove(e));
    this.canvas.addEventListener('mousedown', (e) => this.handleMouseDown(e));
    this.canvas.addEventListener('mouseup', (e) => this.handleMouseUp(e));
    this.canvas.addEventListener('wheel', (e) => this.handleWheel(e));

    // Keyboard events
    window.addEventListener('keydown', (e) => this.handleKeyDown(e));
    window.addEventListener('keypress', (e) => this.handleKeyPress(e));
  }

  /**
   * Attiva un tool
   * @param {string} toolName - Nome del tool
   */
  setTool(toolName) {
    // Deattiva tool corrente
    if (this.currentTool && this.currentTool.deactivate) {
      this.currentTool.deactivate();
    }

    // Attiva nuovo tool
    this.currentToolName = toolName;
    this.currentTool = this.tools[toolName];

    if (this.currentTool && this.currentTool.activate) {
      this.currentTool.activate();
    }

    this.render();
  }

  /**
   * Imposta status message
   * @param {string} message - Messaggio
   */
  setStatus(message) {
    this.statusMessage = message;
    // Puoi anche emettere evento per UI esterna
    this.canvas.dispatchEvent(new CustomEvent('status-change', { detail: message }));
  }

  /**
   * Handle click
   * @param {MouseEvent} event - Mouse event
   */
  handleClick(event) {
    const point = this.screenToCanvas(event.clientX, event.clientY);

    if (this.currentTool && this.currentTool.onClick) {
      this.currentTool.onClick(point, event);
    }
  }

  /**
   * Handle mouse move
   * @param {MouseEvent} event - Mouse event
   */
  handleMouseMove(event) {
    const point = this.screenToCanvas(event.clientX, event.clientY);

    if (this.currentTool && this.currentTool.onMouseMove) {
      this.currentTool.onMouseMove(point, event);
    }
  }

  /**
   * Handle mouse down
   * @param {MouseEvent} event - Mouse event
   */
  handleMouseDown(event) {
    const point = this.screenToCanvas(event.clientX, event.clientY);

    if (this.currentTool && this.currentTool.onMouseDown) {
      this.currentTool.onMouseDown(point, event);
    }
  }

  /**
   * Handle mouse up
   * @param {MouseEvent} event - Mouse event
   */
  handleMouseUp(event) {
    const point = this.screenToCanvas(event.clientX, event.clientY);

    if (this.currentTool && this.currentTool.onMouseUp) {
      this.currentTool.onMouseUp(point, event);
    }
  }

  /**
   * Handle wheel (zoom)
   * @param {WheelEvent} event - Wheel event
   */
  handleWheel(event) {
    event.preventDefault();

    const delta = event.deltaY > 0 ? 0.9 : 1.1;
    this.zoom *= delta;
    this.zoom = Math.max(0.1, Math.min(10, this.zoom));

    this.render();
  }

  /**
   * Handle key down
   * @param {KeyboardEvent} event - Keyboard event
   */
  handleKeyDown(event) {
    // Undo/Redo
    if (event.ctrlKey || event.metaKey) {
      if (event.key === 'z') {
        event.preventDefault();
        this.undo();
      } else if (event.key === 'y') {
        event.preventDefault();
        this.redo();
      }
    }

    // Escape - cancella operazione corrente
    if (event.key === 'Escape') {
      if (this.currentTool && this.currentTool.deactivate) {
        this.currentTool.deactivate();
        this.currentTool.activate();
      }
      this.render();
    }

    // Delete - elimina oggetto selezionato
    if (event.key === 'Delete') {
      // TODO: implement selection and delete
    }
  }

  /**
   * Handle key press
   * @param {KeyboardEvent} event - Keyboard event
   */
  handleKeyPress(event) {
    if (this.currentTool && this.currentTool.onKeyPress) {
      this.currentTool.onKeyPress(event.key, event);
    }
  }

  /**
   * Converti coordinate schermo in coordinate canvas
   * @param {number} screenX - X coordinate schermo
   * @param {number} screenY - Y coordinate schermo
   * @returns {Object} Punto {x, y} in coordinate world
   */
  screenToCanvas(screenX, screenY) {
    const rect = this.canvas.getBoundingClientRect();
    let x = (screenX - rect.left - this.offset.x) / this.zoom;
    let y = (screenY - rect.top - this.offset.y) / this.zoom;

    // Snap to grid se attivo
    if (this.snapToGrid) {
      x = Math.round(x / this.gridSize) * this.gridSize;
      y = Math.round(y / this.gridSize) * this.gridSize;
    }

    return { x, y };
  }

  /**
   * Converti coordinate canvas in coordinate schermo
   * @param {number} x - X coordinate world
   * @param {number} y - Y coordinate world
   * @returns {Object} Punto {x, y} in coordinate schermo
   */
  canvasToScreen(x, y) {
    return {
      x: x * this.zoom + this.offset.x,
      y: y * this.zoom + this.offset.y
    };
  }

  /**
   * Trova oggetto alle coordinate
   * @param {Object} point - Punto {x, y}
   * @param {number} tolerance - Tolleranza in mm (default 5)
   * @returns {Object|null} Oggetto trovato
   */
  getObjectAt(point, tolerance = 5) {
    // Itera al contrario (ultimi disegnati = sopra)
    for (let i = this.objects.length - 1; i >= 0; i--) {
      const obj = this.objects[i];

      if (this.isPointNearObject(point, obj, tolerance)) {
        return obj;
      }
    }

    return null;
  }

  /**
   * Verifica se punto è vicino a oggetto
   * @param {Object} point - Punto {x, y}
   * @param {Object} object - Oggetto
   * @param {number} tolerance - Tolleranza
   * @returns {boolean}
   */
  isPointNearObject(point, object, tolerance) {
    if (object.type === 'line') {
      return this.distancePointToLine(point, object.p1, object.p2) < tolerance;
    }

    if (object.type === 'circle') {
      const dist = Math.hypot(point.x - object.cx, point.y - object.cy);
      return Math.abs(dist - object.radius) < tolerance;
    }

    if (object.type === 'arc') {
      const dist = Math.hypot(point.x - object.cx, point.y - object.cy);
      const angle = Math.atan2(point.y - object.cy, point.x - object.cx);

      // Verifica se angolo è nel range dell'arco
      const inRange = this.isAngleInRange(angle, object.startAngle, object.endAngle);

      return Math.abs(dist - object.radius) < tolerance && inRange;
    }

    if (object.type === 'rectangle') {
      // Check all 4 edges of rectangle
      const edges = [
        { p1: { x: object.x, y: object.y }, p2: { x: object.x + object.width, y: object.y } },
        { p1: { x: object.x + object.width, y: object.y }, p2: { x: object.x + object.width, y: object.y + object.height } },
        { p1: { x: object.x + object.width, y: object.y + object.height }, p2: { x: object.x, y: object.y + object.height } },
        { p1: { x: object.x, y: object.y + object.height }, p2: { x: object.x, y: object.y } }
      ];

      for (const edge of edges) {
        if (this.distancePointToLine(point, edge.p1, edge.p2) < tolerance) {
          return true;
        }
      }
      return false;
    }

    if (object.type === 'polygon' && object.points && object.points.length > 1) {
      // Check all edges of polygon
      for (let i = 0; i < object.points.length; i++) {
        const p1 = object.points[i];
        const p2 = object.points[(i + 1) % object.points.length];
        if (this.distancePointToLine(point, p1, p2) < tolerance) {
          return true;
        }
      }
      return false;
    }

    if (object.type === 'ellipse') {
      // Simplified ellipse detection (approximate)
      const dx = (point.x - object.cx) / object.rx;
      const dy = (point.y - object.cy) / object.ry;
      const dist = Math.sqrt(dx * dx + dy * dy);
      return Math.abs(dist - 1) < (tolerance / Math.max(object.rx, object.ry));
    }

    if (object.type === 'spline' && object.points && object.points.length > 1) {
      // Check distance to each point (simplified)
      for (let i = 0; i < object.points.length - 1; i++) {
        if (this.distancePointToLine(point, object.points[i], object.points[i + 1]) < tolerance) {
          return true;
        }
      }
      return false;
    }

    if (object.type === 'text') {
      // Simple bounding box check for text
      const textWidth = object.size * (object.text?.length || 0) * 0.6; // Approximate
      const textHeight = object.size || 12;
      return point.x >= object.x && point.x <= object.x + textWidth &&
             point.y >= object.y - textHeight && point.y <= object.y;
    }

    return false;
  }

  /**
   * Distanza punto-linea
   * @param {Object} point - Punto
   * @param {Object} lineP1 - Primo punto linea
   * @param {Object} lineP2 - Secondo punto linea
   * @returns {number} Distanza
   */
  distancePointToLine(point, lineP1, lineP2) {
    const dx = lineP2.x - lineP1.x;
    const dy = lineP2.y - lineP1.y;
    const len = Math.sqrt(dx * dx + dy * dy);

    if (len < 1e-10) return Math.hypot(point.x - lineP1.x, point.y - lineP1.y);

    const t = Math.max(0, Math.min(1, ((point.x - lineP1.x) * dx + (point.y - lineP1.y) * dy) / (len * len)));

    const projX = lineP1.x + t * dx;
    const projY = lineP1.y + t * dy;

    return Math.hypot(point.x - projX, point.y - projY);
  }

  /**
   * Verifica se angolo è nel range
   * @param {number} angle - Angolo
   * @param {number} start - Start angle
   * @param {number} end - End angle
   * @returns {boolean}
   */
  isAngleInRange(angle, start, end) {
    const normalize = (a) => {
      while (a < 0) a += 2 * Math.PI;
      while (a >= 2 * Math.PI) a -= 2 * Math.PI;
      return a;
    };

    angle = normalize(angle);
    start = normalize(start);
    end = normalize(end);

    if (start <= end) {
      return angle >= start && angle <= end;
    } else {
      return angle >= start || angle <= end;
    }
  }

  /**
   * Aggiungi oggetto
   * @param {Object} object - Oggetto
   */
  addObject(object) {
    this.objects.push(object);
  }

  /**
   * Rimuovi oggetto
   * @param {Object} object - Oggetto
   */
  removeObject(object) {
    const index = this.objects.indexOf(object);
    if (index > -1) {
      this.objects.splice(index, 1);
    }
  }

  /**
   * Salva stato corrente nella history
   */
  saveHistory() {
    // Rimuovi stati futuri se siamo nel mezzo della history
    if (this.historyIndex < this.history.length - 1) {
      this.history = this.history.slice(0, this.historyIndex + 1);
    }

    // Aggiungi stato corrente
    this.history.push(JSON.parse(JSON.stringify(this.objects)));
    this.historyIndex++;

    // Limita dimensione history
    if (this.history.length > this.maxHistory) {
      this.history.shift();
      this.historyIndex--;
    }
  }

  /**
   * Undo
   */
  undo() {
    if (this.historyIndex > 0) {
      this.historyIndex--;
      this.objects = JSON.parse(JSON.stringify(this.history[this.historyIndex]));
      this.render();
      this.setStatus('Undo');
    }
  }

  /**
   * Redo
   */
  redo() {
    if (this.historyIndex < this.history.length - 1) {
      this.historyIndex++;
      this.objects = JSON.parse(JSON.stringify(this.history[this.historyIndex]));
      this.render();
      this.setStatus('Redo');
    }
  }

  /**
   * Render completo
   */
  render() {
    const startTime = this.enableProfiling ? performance.now() : 0;

    this.clearCanvas();
    this.drawGrid();
    this.drawObjects();
    this.drawHighlight();
    this.drawToolPreview();
    this.drawStatusBar();

    if (this.enableProfiling) {
      const renderTime = performance.now() - startTime;
      this.updateProfiling(renderTime);
      this.drawProfilingInfo();
    }
  }

  /**
   * Update profiling statistics
   * @param {number} renderTime - Render time in ms
   */
  updateProfiling(renderTime) {
    this.profiling.lastRenderTime = renderTime;
    this.profiling.renderCount++;
    this.profiling.maxRenderTime = Math.max(this.profiling.maxRenderTime, renderTime);

    // Calculate rolling average (last 60 frames)
    const alpha = 1 / Math.min(60, this.profiling.renderCount);
    this.profiling.avgRenderTime = this.profiling.avgRenderTime * (1 - alpha) + renderTime * alpha;

    // Calculate FPS
    const now = Date.now();
    const deltaTime = now - this.profiling.lastFrameTime;
    this.profiling.lastFrameTime = now;
    this.profiling.fps = deltaTime > 0 ? 1000 / deltaTime : 0;
  }

  /**
   * Draw profiling information overlay
   */
  drawProfilingInfo() {
    this.ctx.save();

    // Semi-transparent background
    this.ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
    this.ctx.fillRect(10, 40, 220, 120);

    // White text
    this.ctx.fillStyle = '#00ff00';
    this.ctx.font = '12px monospace';

    const info = [
      `Objects: ${this.objects.length}`,
      `FPS: ${this.profiling.fps.toFixed(1)}`,
      `Last: ${this.profiling.lastRenderTime.toFixed(2)}ms`,
      `Avg: ${this.profiling.avgRenderTime.toFixed(2)}ms`,
      `Max: ${this.profiling.maxRenderTime.toFixed(2)}ms`,
      `Frames: ${this.profiling.renderCount}`,
      `Zoom: ${(this.zoom * 100).toFixed(0)}%`
    ];

    info.forEach((line, i) => {
      this.ctx.fillText(line, 20, 60 + i * 16);
    });

    this.ctx.restore();
  }

  /**
   * Toggle performance profiling
   * @param {boolean} enabled - Enable/disable profiling
   */
  toggleProfiling(enabled) {
    this.enableProfiling = enabled;
    if (enabled) {
      // Reset stats
      this.profiling = {
        lastRenderTime: 0,
        avgRenderTime: 0,
        renderCount: 0,
        maxRenderTime: 0,
        fps: 0,
        lastFrameTime: Date.now()
      };
    }
    this.render();
  }

  /**
   * Get performance statistics
   * @returns {Object} Performance stats
   */
  getPerformanceStats() {
    return {
      ...this.profiling,
      objectCount: this.objects.length,
      zoom: this.zoom
    };
  }

  /**
   * Clear canvas
   */
  clearCanvas() {
    this.ctx.fillStyle = '#ffffff';
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
  }

  /**
   * Disegna griglia
   */
  drawGrid() {
    if (!this.showGrid) return;

    this.ctx.save();
    this.ctx.translate(this.offset.x, this.offset.y);
    this.ctx.scale(this.zoom, this.zoom);

    const gridExtent = 2000;

    // Light grid
    this.ctx.strokeStyle = '#e0e0e0';
    this.ctx.lineWidth = 0.5 / this.zoom;

    for (let x = 0; x <= gridExtent; x += this.gridSize) {
      this.ctx.beginPath();
      this.ctx.moveTo(x, 0);
      this.ctx.lineTo(x, gridExtent);
      this.ctx.stroke();
    }

    for (let y = 0; y <= gridExtent; y += this.gridSize) {
      this.ctx.beginPath();
      this.ctx.moveTo(0, y);
      this.ctx.lineTo(gridExtent, y);
      this.ctx.stroke();
    }

    // Bold lines every 100mm
    this.ctx.strokeStyle = '#c0c0c0';
    this.ctx.lineWidth = 1 / this.zoom;

    for (let x = 0; x <= gridExtent; x += 100) {
      this.ctx.beginPath();
      this.ctx.moveTo(x, 0);
      this.ctx.lineTo(x, gridExtent);
      this.ctx.stroke();
    }

    for (let y = 0; y <= gridExtent; y += 100) {
      this.ctx.beginPath();
      this.ctx.moveTo(0, y);
      this.ctx.lineTo(gridExtent, y);
      this.ctx.stroke();
    }

    // Axes
    this.ctx.strokeStyle = '#666';
    this.ctx.lineWidth = 2 / this.zoom;
    this.ctx.beginPath();
    this.ctx.moveTo(0, 0);
    this.ctx.lineTo(gridExtent, 0);
    this.ctx.moveTo(0, 0);
    this.ctx.lineTo(0, gridExtent);
    this.ctx.stroke();

    this.ctx.restore();
  }

  /**
   * Disegna tutti gli oggetti
   */
  drawObjects() {
    this.ctx.save();
    this.ctx.translate(this.offset.x, this.offset.y);
    this.ctx.scale(this.zoom, this.zoom);

    for (const obj of this.objects) {
      this.drawObject(this.ctx, obj);
    }

    this.ctx.restore();
  }

  /**
   * Disegna singolo oggetto
   * @param {CanvasRenderingContext2D} ctx - Context
   * @param {Object} object - Oggetto
   */
  drawObject(ctx, object) {
    // Setup common style
    const lineType = object.lineType || 'cut';
    ctx.strokeStyle = this.getLineTypeColor(lineType);
    ctx.lineWidth = this.getLineTypeWidth(lineType) / this.zoom;
    ctx.setLineDash(this.getLineTypeDash(lineType, this.zoom));

    // Render by type
    if (object.type === 'line') {
      ctx.beginPath();
      ctx.moveTo(object.p1.x, object.p1.y);
      ctx.lineTo(object.p2.x, object.p2.y);
      ctx.stroke();
    }
    else if (object.type === 'circle') {
      ctx.beginPath();
      ctx.arc(object.cx, object.cy, object.radius, 0, 2 * Math.PI);
      ctx.stroke();
    }
    else if (object.type === 'arc') {
      ctx.beginPath();
      ctx.arc(
        object.cx,
        object.cy,
        object.radius,
        object.startAngle,
        object.endAngle,
        object.counterclockwise || false
      );
      ctx.stroke();
    }
    else if (object.type === 'rectangle') {
      ctx.beginPath();
      ctx.rect(object.x, object.y, object.width, object.height);
      ctx.stroke();
    }
    else if (object.type === 'polygon') {
      if (object.points && object.points.length > 0) {
        ctx.beginPath();
        ctx.moveTo(object.points[0].x, object.points[0].y);
        for (let i = 1; i < object.points.length; i++) {
          ctx.lineTo(object.points[i].x, object.points[i].y);
        }
        ctx.closePath();
        ctx.stroke();
      }
    }
    else if (object.type === 'ellipse') {
      ctx.beginPath();
      ctx.ellipse(
        object.cx,
        object.cy,
        object.rx,
        object.ry,
        object.rotation || 0,
        0,
        2 * Math.PI
      );
      ctx.stroke();
    }
    else if (object.type === 'spline') {
      if (object.points && object.points.length > 1) {
        ctx.beginPath();
        ctx.moveTo(object.points[0].x, object.points[0].y);

        // Simple quadratic curves between points
        for (let i = 1; i < object.points.length - 1; i++) {
          const xc = (object.points[i].x + object.points[i + 1].x) / 2;
          const yc = (object.points[i].y + object.points[i + 1].y) / 2;
          ctx.quadraticCurveTo(object.points[i].x, object.points[i].y, xc, yc);
        }

        // Last point
        const last = object.points[object.points.length - 1];
        ctx.lineTo(last.x, last.y);
        ctx.stroke();
      }
    }
    else if (object.type === 'text') {
      ctx.save();
      ctx.fillStyle = ctx.strokeStyle;
      ctx.font = `${object.size || 12}px ${object.font || 'Arial'}`;
      ctx.fillText(object.text || '', object.x, object.y);
      ctx.restore();
    }

    // Reset line dash
    ctx.setLineDash([]);
  }

  /**
   * Ottieni colore per tipo linea
   * @param {string} lineType - Tipo linea
   * @returns {string} Colore
   */
  getLineTypeColor(lineType) {
    switch (lineType) {
      case 'cut': return '#ff0000';
      case 'crease': return '#0000ff';
      case 'perforation': return '#ff00ff';
      case 'bleed': return '#00ff00';
      default: return '#000000';
    }
  }

  /**
   * Ottieni spessore per tipo linea
   * @param {string} lineType - Tipo linea
   * @returns {number} Spessore
   */
  getLineTypeWidth(lineType) {
    switch (lineType) {
      case 'cut': return 2;
      case 'crease': return 1;
      case 'perforation': return 1;
      case 'bleed': return 0.5;
      default: return 1;
    }
  }

  /**
   * Ottieni dash pattern per tipo linea
   * @param {string} lineType - Tipo linea
   * @param {number} zoom - Zoom corrente
   * @returns {Array} Dash pattern
   */
  getLineTypeDash(lineType, zoom) {
    switch (lineType) {
      case 'crease': return [5 / zoom, 5 / zoom];
      case 'perforation': return [2 / zoom, 3 / zoom];
      default: return [];
    }
  }

  /**
   * Disegna highlight oggetto sotto cursore
   */
  drawHighlight() {
    if (!this.highlightObject) return;

    this.ctx.save();
    this.ctx.translate(this.offset.x, this.offset.y);
    this.ctx.scale(this.zoom, this.zoom);

    this.ctx.strokeStyle = '#ffff00';
    this.ctx.lineWidth = 3 / this.zoom;

    this.drawObject(this.ctx, this.highlightObject);

    this.ctx.restore();
  }

  /**
   * Disegna preview del tool corrente
   */
  drawToolPreview() {
    if (!this.currentTool || !this.currentTool.renderPreview) return;

    this.ctx.save();
    this.ctx.translate(this.offset.x, this.offset.y);
    this.ctx.scale(this.zoom, this.zoom);

    this.currentTool.renderPreview(this.ctx);

    this.ctx.restore();
  }

  /**
   * Disegna status bar
   */
  drawStatusBar() {
    this.ctx.save();

    this.ctx.fillStyle = '#f0f0f0';
    this.ctx.fillRect(0, this.canvas.height - 30, this.canvas.width, 30);

    this.ctx.fillStyle = '#000';
    this.ctx.font = '12px Arial';
    this.ctx.fillText(this.statusMessage, 10, this.canvas.height - 10);

    // Tool corrente
    if (this.currentToolName) {
      this.ctx.fillText(`Tool: ${this.currentToolName}`, 400, this.canvas.height - 10);
    }

    // Zoom
    this.ctx.fillText(`Zoom: ${(this.zoom * 100).toFixed(0)}%`, 600, this.canvas.height - 10);

    this.ctx.restore();
  }
}
