/**
 * Move Tool - Fusion 360 Style
 * Sposta oggetti selezionati con drag, snap e input coordinate
 *
 * @module MoveTool
 * @author Box Designer CAD Engine
 */

export class MoveTool {
  /**
   * Costruttore Move Tool
   * @param {Object} cadEngine - Riferimento al CAD engine principale
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'move';
    this.cursor = 'move';

    // Move state
    this.isMoving = false;
    this.moveStartPoint = null;
    this.currentPoint = null;
    this.objectsToMove = [];
    this.originalPositions = [];

    // Snap settings
    this.snapToGrid = true;
    this.snapToObjects = true;
    this.snapTolerance = 10; // mm

    // Ghost preview settings
    this.ghostOpacity = 0.5;
    this.ghostColor = '#00aaff';

    // Coordinate input mode
    this.coordinateInputMode = false;
    this.coordinateInput = { x: 0, y: 0 };
  }

  /**
   * Attiva il tool
   */
  activate() {
    // Get selected objects from SelectTool
    const selectTool = this.cad.tools.select;
    if (selectTool && selectTool.selectedObjects.length > 0) {
      this.objectsToMove = [...selectTool.selectedObjects];
      this.saveOriginalPositions();
      this.updateStatus();
    } else {
      this.cad.setStatus('MOVE: No objects selected. Use Select tool first (press S)');
      this.objectsToMove = [];
    }
  }

  /**
   * Deattiva il tool
   */
  deactivate() {
    this.isMoving = false;
    this.coordinateInputMode = false;
  }

  /**
   * Salva posizioni originali degli oggetti
   */
  saveOriginalPositions() {
    this.originalPositions = this.objectsToMove.map(obj => {
      return this.getObjectPosition(obj);
    });
  }

  /**
   * Ottiene la posizione di un oggetto (reference point)
   * @param {Object} obj - Oggetto CAD
   * @returns {Object} - {x, y}
   */
  getObjectPosition(obj) {
    if (obj.type === 'line') {
      return { x: obj.p1.x, y: obj.p1.y };
    }
    else if (obj.type === 'rectangle') {
      return { x: obj.x, y: obj.y };
    }
    else if (obj.type === 'circle') {
      return { x: obj.cx, y: obj.cy };
    }
    else if (obj.type === 'arc') {
      return { x: obj.cx, y: obj.cy };
    }
    else if (obj.type === 'ellipse') {
      return { x: obj.cx, y: obj.cy };
    }
    else if (obj.type === 'polygon' && obj.points && obj.points.length > 0) {
      return { x: obj.points[0].x, y: obj.points[0].y };
    }
    else if (obj.type === 'spline' && obj.points && obj.points.length > 0) {
      return { x: obj.points[0].x, y: obj.points[0].y };
    }
    else if (obj.type === 'text') {
      return { x: obj.x, y: obj.y };
    }

    return { x: 0, y: 0 };
  }

  /**
   * Aggiorna status message
   */
  updateStatus() {
    const count = this.objectsToMove.length;

    if (this.coordinateInputMode) {
      this.cad.setStatus(`MOVE: Enter offset - X: ${this.coordinateInput.x.toFixed(2)}mm, Y: ${this.coordinateInput.y.toFixed(2)}mm (Enter to apply, Esc to cancel)`);
    }
    else if (this.isMoving) {
      const dx = this.currentPoint.x - this.moveStartPoint.x;
      const dy = this.currentPoint.y - this.moveStartPoint.y;
      const distance = Math.sqrt(dx * dx + dy * dy);
      this.cad.setStatus(`MOVE: ${count} object(s) - ΔX: ${dx.toFixed(2)}mm, ΔY: ${dy.toFixed(2)}mm, Distance: ${distance.toFixed(2)}mm`);
    }
    else if (count === 0) {
      this.cad.setStatus('MOVE: No objects selected. Press S for Select tool');
    }
    else if (count === 1) {
      this.cad.setStatus('MOVE: 1 object ready - Click to start move, M for coordinate input, S for snap toggle');
    }
    else {
      this.cad.setStatus(`MOVE: ${count} objects ready - Click to start move, M for coordinate input, S for snap toggle`);
    }
  }

  /**
   * Click handler - unused for move (using mouse down/move/up)
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onClick(point, event) {
    // Move uses drag pattern, not click
  }

  /**
   * Mouse down handler - start move
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onMouseDown(point, event) {
    if (this.objectsToMove.length === 0) return;
    if (this.coordinateInputMode) return;

    this.isMoving = true;
    this.moveStartPoint = { ...point };
    this.currentPoint = { ...point };
    this.updateStatus();
  }

  /**
   * Mouse move handler - preview move
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onMouseMove(point, event) {
    if (!this.isMoving) return;

    // Apply constraints
    let finalPoint = { ...point };

    // Snap to grid
    if (this.snapToGrid && this.cad.snapToGrid) {
      finalPoint = this.cad.snapPoint(finalPoint);
    }

    // Snap to objects
    if (this.snapToObjects) {
      const snappedPoint = this.findSnapPoint(finalPoint);
      if (snappedPoint) {
        finalPoint = snappedPoint;
      }
    }

    this.currentPoint = finalPoint;
    this.updateStatus();
    this.cad.render();
  }

  /**
   * Mouse up handler - complete move
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onMouseUp(point, event) {
    if (!this.isMoving) return;

    // Apply final move
    const dx = this.currentPoint.x - this.moveStartPoint.x;
    const dy = this.currentPoint.y - this.moveStartPoint.y;

    this.applyMove(dx, dy);

    // Reset state
    this.isMoving = false;
    this.moveStartPoint = null;
    this.currentPoint = null;

    // Save to history
    this.cad.saveHistory();
    this.cad.render();
    this.updateStatus();
  }

  /**
   * Applica spostamento agli oggetti
   * @param {Number} dx - Offset X
   * @param {Number} dy - Offset Y
   */
  applyMove(dx, dy) {
    for (const obj of this.objectsToMove) {
      this.moveObject(obj, dx, dy);
    }
  }

  /**
   * Sposta un singolo oggetto
   * @param {Object} obj - Oggetto CAD
   * @param {Number} dx - Offset X
   * @param {Number} dy - Offset Y
   */
  moveObject(obj, dx, dy) {
    if (obj.type === 'line') {
      obj.p1.x += dx;
      obj.p1.y += dy;
      obj.p2.x += dx;
      obj.p2.y += dy;
    }
    else if (obj.type === 'rectangle') {
      obj.x += dx;
      obj.y += dy;
    }
    else if (obj.type === 'circle') {
      obj.cx += dx;
      obj.cy += dy;
    }
    else if (obj.type === 'arc') {
      obj.cx += dx;
      obj.cy += dy;
    }
    else if (obj.type === 'ellipse') {
      obj.cx += dx;
      obj.cy += dy;
    }
    else if (obj.type === 'polygon' && obj.points) {
      for (const point of obj.points) {
        point.x += dx;
        point.y += dy;
      }
    }
    else if (obj.type === 'spline' && obj.points) {
      for (const point of obj.points) {
        point.x += dx;
        point.y += dy;
      }
    }
    else if (obj.type === 'text') {
      obj.x += dx;
      obj.y += dy;
    }
  }

  /**
   * Trova snap point vicino
   * @param {Object} point - Punto {x, y}
   * @returns {Object|null} - Snapped point o null
   */
  findSnapPoint(point) {
    const tolerance = this.snapTolerance;
    let closestPoint = null;
    let closestDistance = tolerance;

    // Snap to other objects (not being moved)
    for (const obj of this.cad.objects) {
      // Skip objects being moved
      if (this.objectsToMove.includes(obj)) continue;

      const snapPoints = this.getObjectSnapPoints(obj);

      for (const snapPoint of snapPoints) {
        const dx = snapPoint.x - point.x;
        const dy = snapPoint.y - point.y;
        const distance = Math.sqrt(dx * dx + dy * dy);

        if (distance < closestDistance) {
          closestDistance = distance;
          closestPoint = snapPoint;
        }
      }
    }

    return closestPoint;
  }

  /**
   * Ottiene punti di snap per un oggetto
   * @param {Object} obj - Oggetto CAD
   * @returns {Array} - Array di {x, y}
   */
  getObjectSnapPoints(obj) {
    const points = [];

    if (obj.type === 'line') {
      points.push(obj.p1, obj.p2); // Endpoints
      points.push({
        x: (obj.p1.x + obj.p2.x) / 2,
        y: (obj.p1.y + obj.p2.y) / 2
      }); // Midpoint
    }
    else if (obj.type === 'rectangle') {
      points.push({ x: obj.x, y: obj.y }); // Top-left
      points.push({ x: obj.x + obj.width, y: obj.y }); // Top-right
      points.push({ x: obj.x + obj.width, y: obj.y + obj.height }); // Bottom-right
      points.push({ x: obj.x, y: obj.y + obj.height }); // Bottom-left
      points.push({
        x: obj.x + obj.width / 2,
        y: obj.y + obj.height / 2
      }); // Center
    }
    else if (obj.type === 'circle') {
      points.push({ x: obj.cx, y: obj.cy }); // Center
      points.push({ x: obj.cx + obj.radius, y: obj.cy }); // Right
      points.push({ x: obj.cx - obj.radius, y: obj.cy }); // Left
      points.push({ x: obj.cx, y: obj.cy + obj.radius }); // Bottom
      points.push({ x: obj.cx, y: obj.cy - obj.radius }); // Top
    }
    else if (obj.type === 'polygon' && obj.points) {
      points.push(...obj.points);
    }

    return points;
  }

  /**
   * Key press handler
   * @param {String} key - Key name
   * @param {Event} event - Keyboard event
   */
  onKeyPress(key, event) {
    // ESC - cancel move or exit coordinate input
    if (key === 'Escape') {
      if (this.isMoving) {
        // Cancel move - restore original positions
        this.restoreOriginalPositions();
        this.isMoving = false;
        this.moveStartPoint = null;
        this.currentPoint = null;
        this.cad.render();
      }
      else if (this.coordinateInputMode) {
        this.coordinateInputMode = false;
        this.coordinateInput = { x: 0, y: 0 };
      }
      this.updateStatus();
      return;
    }

    // M - toggle coordinate input mode
    if (key.toLowerCase() === 'm' && !event.ctrlKey && !event.metaKey) {
      if (this.objectsToMove.length > 0 && !this.isMoving) {
        this.coordinateInputMode = !this.coordinateInputMode;
        if (this.coordinateInputMode) {
          this.coordinateInput = { x: 0, y: 0 };
          this.promptCoordinateInput();
        }
        this.updateStatus();
      }
      return;
    }

    // S - toggle snap to objects
    if (key.toLowerCase() === 's' && !event.ctrlKey && !event.metaKey && this.isMoving) {
      this.snapToObjects = !this.snapToObjects;
      this.cad.setStatus(`MOVE: Snap to objects ${this.snapToObjects ? 'ON' : 'OFF'}`);
      setTimeout(() => this.updateStatus(), 1000);
      return;
    }

    // G - toggle snap to grid
    if (key.toLowerCase() === 'g' && !event.ctrlKey && !event.metaKey && this.isMoving) {
      this.snapToGrid = !this.snapToGrid;
      this.cad.setStatus(`MOVE: Snap to grid ${this.snapToGrid ? 'ON' : 'OFF'}`);
      setTimeout(() => this.updateStatus(), 1000);
      return;
    }
  }

  /**
   * Ripristina posizioni originali (cancel move)
   */
  restoreOriginalPositions() {
    for (let i = 0; i < this.objectsToMove.length; i++) {
      const obj = this.objectsToMove[i];
      const originalPos = this.originalPositions[i];
      const currentPos = this.getObjectPosition(obj);

      const dx = originalPos.x - currentPos.x;
      const dy = originalPos.y - currentPos.y;

      this.moveObject(obj, dx, dy);
    }
  }

  /**
   * Prompt per coordinate input
   */
  promptCoordinateInput() {
    const offsetX = prompt('Enter X offset (mm):', '0');
    if (offsetX === null) {
      this.coordinateInputMode = false;
      this.updateStatus();
      return;
    }

    const offsetY = prompt('Enter Y offset (mm):', '0');
    if (offsetY === null) {
      this.coordinateInputMode = false;
      this.updateStatus();
      return;
    }

    const dx = parseFloat(offsetX) || 0;
    const dy = parseFloat(offsetY) || 0;

    // Apply move
    this.applyMove(dx, dy);
    this.saveOriginalPositions(); // Update for potential next move

    // Save to history
    this.cad.saveHistory();
    this.cad.render();

    this.coordinateInputMode = false;
    this.updateStatus();
  }

  /**
   * Render preview
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   */
  renderPreview(ctx) {
    if (!this.isMoving || !this.moveStartPoint || !this.currentPoint) return;

    const dx = this.currentPoint.x - this.moveStartPoint.x;
    const dy = this.currentPoint.y - this.moveStartPoint.y;

    // Save context
    ctx.save();

    // Draw ghost preview of moved objects
    ctx.globalAlpha = this.ghostOpacity;
    ctx.strokeStyle = this.ghostColor;
    ctx.fillStyle = this.ghostColor;

    for (const obj of this.objectsToMove) {
      // Create temporary moved object
      const movedObj = this.createMovedObject(obj, dx, dy);

      // Draw the moved object
      this.cad.drawObject(ctx, movedObj);
    }

    // Restore context
    ctx.restore();

    // Draw move vector (arrow from start to current)
    ctx.save();
    ctx.strokeStyle = '#ff00ff';
    ctx.lineWidth = 2 / this.cad.zoom;
    ctx.setLineDash([5, 5]);

    ctx.beginPath();
    ctx.moveTo(this.moveStartPoint.x, this.moveStartPoint.y);
    ctx.lineTo(this.currentPoint.x, this.currentPoint.y);
    ctx.stroke();

    // Arrow head
    const angle = Math.atan2(dy, dx);
    const arrowSize = 10 / this.cad.zoom;

    ctx.beginPath();
    ctx.moveTo(this.currentPoint.x, this.currentPoint.y);
    ctx.lineTo(
      this.currentPoint.x - arrowSize * Math.cos(angle - Math.PI / 6),
      this.currentPoint.y - arrowSize * Math.sin(angle - Math.PI / 6)
    );
    ctx.moveTo(this.currentPoint.x, this.currentPoint.y);
    ctx.lineTo(
      this.currentPoint.x - arrowSize * Math.cos(angle + Math.PI / 6),
      this.currentPoint.y - arrowSize * Math.sin(angle + Math.PI / 6)
    );
    ctx.stroke();

    ctx.restore();

    // Draw snap indicator
    if (this.snapToObjects) {
      const snappedPoint = this.findSnapPoint(this.currentPoint);
      if (snappedPoint) {
        ctx.save();
        ctx.fillStyle = '#00ff00';
        const size = 8 / this.cad.zoom;
        ctx.beginPath();
        ctx.arc(snappedPoint.x, snappedPoint.y, size, 0, 2 * Math.PI);
        ctx.fill();
        ctx.restore();
      }
    }
  }

  /**
   * Crea oggetto spostato temporaneo per preview
   * @param {Object} obj - Oggetto originale
   * @param {Number} dx - Offset X
   * @param {Number} dy - Offset Y
   * @returns {Object} - Oggetto spostato (copia)
   */
  createMovedObject(obj, dx, dy) {
    // Deep clone object
    const movedObj = JSON.parse(JSON.stringify(obj));

    // Apply move
    if (movedObj.type === 'line') {
      movedObj.p1.x += dx;
      movedObj.p1.y += dy;
      movedObj.p2.x += dx;
      movedObj.p2.y += dy;
    }
    else if (movedObj.type === 'rectangle') {
      movedObj.x += dx;
      movedObj.y += dy;
    }
    else if (movedObj.type === 'circle') {
      movedObj.cx += dx;
      movedObj.cy += dy;
    }
    else if (movedObj.type === 'arc') {
      movedObj.cx += dx;
      movedObj.cy += dy;
    }
    else if (movedObj.type === 'ellipse') {
      movedObj.cx += dx;
      movedObj.cy += dy;
    }
    else if (movedObj.type === 'polygon' && movedObj.points) {
      for (const point of movedObj.points) {
        point.x += dx;
        point.y += dy;
      }
    }
    else if (movedObj.type === 'spline' && movedObj.points) {
      for (const point of movedObj.points) {
        point.x += dx;
        point.y += dy;
      }
    }
    else if (movedObj.type === 'text') {
      movedObj.x += dx;
      movedObj.y += dy;
    }

    return movedObj;
  }
}
