/**
 * Select Tool - Fusion 360 Style
 * Seleziona oggetti con click, box selection, multi-select
 *
 * @module SelectTool
 * @author Box Designer CAD Engine
 */

export class SelectTool {
  /**
   * Costruttore Select Tool
   * @param {Object} cadEngine - Riferimento al CAD engine principale
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'select';
    this.cursor = 'default';

    // Selected objects
    this.selectedObjects = [];

    // Box selection state
    this.isBoxSelecting = false;
    this.boxStartPoint = null;
    this.boxCurrentPoint = null;

    // Settings
    this.selectionTolerance = 5; // mm
  }

  /**
   * Attiva il tool
   */
  activate() {
    this.updateStatus();
  }

  /**
   * Deattiva il tool
   */
  deactivate() {
    // Keep selection when switching tools
  }

  /**
   * Aggiorna status message
   */
  updateStatus() {
    const count = this.selectedObjects.length;
    if (count === 0) {
      this.cad.setStatus('SELECT: Click to select, Drag for box selection, Shift+Click for multi-select');
    } else if (count === 1) {
      this.cad.setStatus(`SELECT: 1 object selected (Delete to remove, Esc to deselect)`);
    } else {
      this.cad.setStatus(`SELECT: ${count} objects selected (Delete to remove, Esc to deselect all)`);
    }
  }

  /**
   * Click handler
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onClick(point, event) {
    // Box selection is handled by mouse down/move/up
    if (this.isBoxSelecting) return;

    // Find object at point
    const clickedObject = this.cad.getObjectAt(point, this.selectionTolerance);

    if (event.shiftKey) {
      // Multi-select mode
      if (clickedObject) {
        this.toggleSelection(clickedObject);
      }
    } else {
      // Single select mode
      if (clickedObject) {
        // Select only this object
        this.selectedObjects = [clickedObject];
      } else {
        // Deselect all
        this.selectedObjects = [];
      }
    }

    this.updateStatus();
    this.cad.render();
  }

  /**
   * Mouse down handler (start box selection)
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onMouseDown(point, event) {
    // Check if clicking on an object
    const clickedObject = this.cad.getObjectAt(point, this.selectionTolerance);

    if (!clickedObject) {
      // Start box selection
      this.isBoxSelecting = true;
      this.boxStartPoint = { ...point };
      this.boxCurrentPoint = { ...point };
    }
  }

  /**
   * Mouse move handler (update box selection)
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onMouseMove(point, event) {
    if (this.isBoxSelecting) {
      this.boxCurrentPoint = { ...point };
      this.cad.render();
    } else {
      // Highlight object under cursor
      const hoverObject = this.cad.getObjectAt(point, this.selectionTolerance);
      this.cad.highlightObject = hoverObject;
      this.cad.render();
    }
  }

  /**
   * Mouse up handler (complete box selection)
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onMouseUp(point, event) {
    if (this.isBoxSelecting) {
      this.boxCurrentPoint = { ...point };
      this.performBoxSelection(event.shiftKey);
      this.isBoxSelecting = false;
      this.boxStartPoint = null;
      this.boxCurrentPoint = null;
      this.updateStatus();
      this.cad.render();
    }
  }

  /**
   * Key press handler
   * @param {string} key - Tasto premuto
   * @param {Event} event - Keyboard event
   */
  onKeyPress(key, event) {
    // ESC - deselect all
    if (key === 'Escape') {
      this.selectedObjects = [];
      this.updateStatus();
      this.cad.render();
      return;
    }

    // Delete - remove selected objects
    if (key === 'Delete' || key === 'Backspace') {
      this.deleteSelected();
      return;
    }

    // Ctrl+A - select all
    if ((event.ctrlKey || event.metaKey) && key === 'a') {
      event.preventDefault();
      this.selectAll();
      return;
    }
  }

  /**
   * Toggle selection of object
   * @param {Object} object - Oggetto da toggleare
   */
  toggleSelection(object) {
    const index = this.selectedObjects.indexOf(object);
    if (index > -1) {
      // Already selected, remove
      this.selectedObjects.splice(index, 1);
    } else {
      // Not selected, add
      this.selectedObjects.push(object);
    }
  }

  /**
   * Perform box selection
   * @param {boolean} additive - Se true, aggiunge alla selezione esistente
   */
  performBoxSelection(additive) {
    if (!this.boxStartPoint || !this.boxCurrentPoint) return;

    // Calculate box bounds
    const x1 = Math.min(this.boxStartPoint.x, this.boxCurrentPoint.x);
    const y1 = Math.min(this.boxStartPoint.y, this.boxCurrentPoint.y);
    const x2 = Math.max(this.boxStartPoint.x, this.boxCurrentPoint.x);
    const y2 = Math.max(this.boxStartPoint.y, this.boxCurrentPoint.y);

    // Find objects within box
    const objectsInBox = [];

    for (const obj of this.cad.objects) {
      if (this.isObjectInBox(obj, x1, y1, x2, y2)) {
        objectsInBox.push(obj);
      }
    }

    if (additive) {
      // Add to existing selection (avoid duplicates)
      for (const obj of objectsInBox) {
        if (!this.selectedObjects.includes(obj)) {
          this.selectedObjects.push(obj);
        }
      }
    } else {
      // Replace selection
      this.selectedObjects = objectsInBox;
    }
  }

  /**
   * Check if object is within box
   * @param {Object} obj - Oggetto
   * @param {number} x1 - Box min x
   * @param {number} y1 - Box min y
   * @param {number} x2 - Box max x
   * @param {number} y2 - Box max y
   * @returns {boolean}
   */
  isObjectInBox(obj, x1, y1, x2, y2) {
    if (obj.type === 'line') {
      // Line is in box if both endpoints are in box
      return this.isPointInBox(obj.p1, x1, y1, x2, y2) &&
             this.isPointInBox(obj.p2, x1, y1, x2, y2);
    }

    if (obj.type === 'circle') {
      // Circle is in box if center is in box (simplified)
      return obj.cx >= x1 && obj.cx <= x2 &&
             obj.cy >= y1 && obj.cy <= y2;
    }

    if (obj.type === 'arc') {
      // Arc is in box if center is in box (simplified)
      return obj.cx >= x1 && obj.cx <= x2 &&
             obj.cy >= y1 && obj.cy <= y2;
    }

    if (obj.type === 'rectangle') {
      // Rectangle is in box if all corners are in box
      return obj.x >= x1 && obj.x + obj.width <= x2 &&
             obj.y >= y1 && obj.y + obj.height <= y2;
    }

    if (obj.type === 'polygon' && obj.points) {
      // Polygon is in box if all points are in box
      return obj.points.every(p => this.isPointInBox(p, x1, y1, x2, y2));
    }

    // Default: check if object's center is in box
    return false;
  }

  /**
   * Check if point is within box
   * @param {Object} point - Punto {x, y}
   * @param {number} x1 - Box min x
   * @param {number} y1 - Box min y
   * @param {number} x2 - Box max x
   * @param {number} y2 - Box max y
   * @returns {boolean}
   */
  isPointInBox(point, x1, y1, x2, y2) {
    return point.x >= x1 && point.x <= x2 &&
           point.y >= y1 && point.y <= y2;
  }

  /**
   * Select all objects
   */
  selectAll() {
    this.selectedObjects = [...this.cad.objects];
    this.updateStatus();
    this.cad.render();
  }

  /**
   * Delete selected objects
   */
  deleteSelected() {
    if (this.selectedObjects.length === 0) return;

    // Confirm if deleting many objects
    if (this.selectedObjects.length > 10) {
      if (!confirm(`Delete ${this.selectedObjects.length} objects?`)) {
        return;
      }
    }

    // Remove from objects array
    for (const obj of this.selectedObjects) {
      const index = this.cad.objects.indexOf(obj);
      if (index > -1) {
        this.cad.objects.splice(index, 1);
      }
    }

    // Clear selection
    this.selectedObjects = [];

    // Save to history
    this.cad.saveHistory();
    this.updateStatus();
    this.cad.render();
  }

  /**
   * Get selected objects
   * @returns {Array} Array di oggetti selezionati
   */
  getSelectedObjects() {
    return this.selectedObjects;
  }

  /**
   * Clear selection
   */
  clearSelection() {
    this.selectedObjects = [];
    this.updateStatus();
    this.cad.render();
  }

  /**
   * Render selection highlights
   * @param {CanvasRenderingContext2D} ctx - Context
   */
  renderPreview(ctx) {
    // Render box selection
    if (this.isBoxSelecting && this.boxStartPoint && this.boxCurrentPoint) {
      ctx.save();

      const x1 = Math.min(this.boxStartPoint.x, this.boxCurrentPoint.x);
      const y1 = Math.min(this.boxStartPoint.y, this.boxCurrentPoint.y);
      const width = Math.abs(this.boxCurrentPoint.x - this.boxStartPoint.x);
      const height = Math.abs(this.boxCurrentPoint.y - this.boxStartPoint.y);

      // Selection box
      ctx.strokeStyle = '#00aaff';
      ctx.lineWidth = 1 / this.cad.zoom;
      ctx.setLineDash([5 / this.cad.zoom, 5 / this.cad.zoom]);
      ctx.strokeRect(x1, y1, width, height);

      // Fill with transparent blue
      ctx.fillStyle = 'rgba(0, 170, 255, 0.1)';
      ctx.fillRect(x1, y1, width, height);

      ctx.setLineDash([]);
      ctx.restore();
    }

    // Render selected objects highlight
    if (this.selectedObjects.length > 0) {
      ctx.save();

      ctx.strokeStyle = '#00ff00';
      ctx.lineWidth = 3 / this.cad.zoom;

      for (const obj of this.selectedObjects) {
        this.cad.drawObject(ctx, obj);
      }

      // Draw selection handles (for future move/resize)
      ctx.fillStyle = '#00ff00';
      const handleSize = 6 / this.cad.zoom;

      for (const obj of this.selectedObjects) {
        const handles = this.getObjectHandles(obj);
        for (const handle of handles) {
          ctx.fillRect(
            handle.x - handleSize / 2,
            handle.y - handleSize / 2,
            handleSize,
            handleSize
          );
        }
      }

      ctx.restore();
    }
  }

  /**
   * Get handles for object (for future resize/move)
   * @param {Object} obj - Oggetto
   * @returns {Array} Array di handle points
   */
  getObjectHandles(obj) {
    const handles = [];

    if (obj.type === 'line') {
      handles.push(obj.p1, obj.p2);
    } else if (obj.type === 'rectangle') {
      handles.push(
        { x: obj.x, y: obj.y },
        { x: obj.x + obj.width, y: obj.y },
        { x: obj.x + obj.width, y: obj.y + obj.height },
        { x: obj.x, y: obj.y + obj.height }
      );
    } else if (obj.type === 'circle') {
      handles.push(
        { x: obj.cx, y: obj.cy },
        { x: obj.cx + obj.radius, y: obj.cy },
        { x: obj.cx - obj.radius, y: obj.cy },
        { x: obj.cx, y: obj.cy + obj.radius },
        { x: obj.cx, y: obj.cy - obj.radius }
      );
    } else if (obj.type === 'polygon' && obj.points) {
      handles.push(...obj.points);
    }

    return handles;
  }
}
