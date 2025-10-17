/**
 * Rotate Tool - Professional CAD Rotation
 * Rotate objects by angle around pivot point
 * Week 4 Day 18
 *
 * Features:
 * - Interactive center point selection
 * - Angle input (manual or drag)
 * - Angle snap (15°, 30°, 45°, 90°)
 * - Real-time preview with ghost objects
 * - Quick rotations (90° CW/CCW)
 * - Works with all object types
 *
 * @module RotateTool
 * @author Box Designer CAD Engine
 */

export class RotateTool {
  /**
   * Constructor
   * @param {CADEngine} cadEngine - Reference to CAD engine
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'rotate';
    this.cursor = 'crosshair';

    // State
    this.state = 'selectObjects'; // 'selectObjects', 'selectCenter', 'setAngle', 'complete'
    this.selectedObjects = [];
    this.centerPoint = null;
    this.angle = 0; // Current rotation angle in radians
    this.startAngle = 0; // Angle at mouse down
    this.previewObjects = [];

    // Options
    this.snapEnabled = true;
    this.snapAngles = [15, 30, 45, 90]; // Degrees
    this.snapThreshold = 5; // Degrees
    this.keepOriginal = false;

    // Interaction
    this.isDragging = false;
    this.hoverPoint = null;
    this.dragStartPoint = null;
  }

  /**
   * Activate tool
   */
  activate() {
    this.state = 'selectObjects';
    this.selectedObjects = [];
    this.centerPoint = null;
    this.angle = 0;
    this.startAngle = 0;
    this.previewObjects = [];
    this.isDragging = false;
    this.hoverPoint = null;
    this.updateStatusMessage();
  }

  /**
   * Update status message
   */
  updateStatusMessage() {
    let msg = 'ROTATE: ';

    switch(this.state) {
      case 'selectObjects':
        msg += `Select objects to rotate | Snap: ${this.snapEnabled ? 'ON' : 'OFF'} (S) | Keep: ${this.keepOriginal ? 'YES' : 'NO'} (K)`;
        break;
      case 'selectCenter':
        msg += `${this.selectedObjects.length} selected | Click rotation center point | Enter = use selection center`;
        break;
      case 'setAngle':
        const degrees = Math.round(this.angle * 180 / Math.PI);
        msg += `Angle: ${degrees}° | Drag to rotate, A = input angle, Q = +90°, W = -90°, Enter = apply`;
        break;
    }

    this.cad.setStatus(msg);
  }

  /**
   * Handle click
   */
  onClick(point, event) {
    switch(this.state) {
      case 'selectObjects':
        this.handleObjectSelection(point, event);
        break;
      case 'selectCenter':
        this.handleCenterSelection(point);
        break;
      case 'setAngle':
        // Click applies rotation
        this.applyRotation();
        break;
    }
  }

  /**
   * Handle object selection
   */
  handleObjectSelection(point, event) {
    const object = this.cad.getObjectAt(point);

    if (object) {
      const index = this.selectedObjects.indexOf(object);

      if (index === -1) {
        // Add to selection
        this.selectedObjects.push(object);
        object._rotateSelected = true;
      } else if (event.shiftKey) {
        // Remove from selection
        this.selectedObjects.splice(index, 1);
        delete object._rotateSelected;
      }

      this.updateStatusMessage();
      this.cad.render();
    }
  }

  /**
   * Handle center point selection
   */
  handleCenterSelection(point) {
    this.centerPoint = { ...point };
    this.state = 'setAngle';
    this.angle = 0;
    this.updatePreview();
    this.updateStatusMessage();
    this.cad.render();
  }

  /**
   * Handle mouse down (start dragging)
   */
  onMouseDown(point, event) {
    if (this.state === 'setAngle') {
      this.isDragging = true;
      this.dragStartPoint = { ...point };

      // Calculate starting angle
      const dx = point.x - this.centerPoint.x;
      const dy = point.y - this.centerPoint.y;
      this.startAngle = Math.atan2(dy, dx);
    }
  }

  /**
   * Handle mouse up (stop dragging)
   */
  onMouseUp(point, event) {
    if (this.isDragging) {
      this.isDragging = false;
      this.dragStartPoint = null;
    }
  }

  /**
   * Handle mouse move
   */
  onMove(point, event) {
    this.hoverPoint = { ...point };

    if (this.state === 'setAngle') {
      if (this.isDragging) {
        // Calculate current angle
        const dx = point.x - this.centerPoint.x;
        const dy = point.y - this.centerPoint.y;
        const currentAngle = Math.atan2(dy, dx);

        // Rotation angle is difference
        let angle = currentAngle - this.startAngle;

        // Apply snap if enabled
        if (this.snapEnabled && !event.shiftKey) {
          angle = this.applyAngleSnap(angle);
        }

        this.angle = angle;
        this.updatePreview();
        this.updateStatusMessage();
      }
      this.cad.render();
    }
  }

  /**
   * Apply angle snapping
   */
  applyAngleSnap(angle) {
    const degrees = angle * 180 / Math.PI;
    const threshold = this.snapThreshold;

    // Check each snap angle
    for (const snapDeg of this.snapAngles) {
      // Check positive and negative
      for (const sign of [1, -1]) {
        const target = snapDeg * sign;
        if (Math.abs(degrees - target) < threshold) {
          return target * Math.PI / 180;
        }
      }
    }

    // Also snap to 0° and 180°
    if (Math.abs(degrees) < threshold) {
      return 0;
    }
    if (Math.abs(Math.abs(degrees) - 180) < threshold) {
      return degrees > 0 ? Math.PI : -Math.PI;
    }

    return angle;
  }

  /**
   * Handle keyboard input
   */
  onKeyDown(event) {
    const key = event.key.toLowerCase();

    // Snap toggle
    if (key === 's') {
      this.snapEnabled = !this.snapEnabled;
      if (this.state === 'setAngle') {
        this.updatePreview();
      }
      this.updateStatusMessage();
      event.preventDefault();
      return true;
    }

    // Keep original toggle
    if (key === 'k') {
      this.keepOriginal = !this.keepOriginal;
      this.updateStatusMessage();
      event.preventDefault();
      return true;
    }

    // Quick rotations
    if (key === 'q') {
      // +90° clockwise
      if (this.state === 'setAngle') {
        this.angle += Math.PI / 2;
        this.updatePreview();
        this.updateStatusMessage();
      }
      event.preventDefault();
      return true;
    }

    if (key === 'w') {
      // -90° counter-clockwise
      if (this.state === 'setAngle') {
        this.angle -= Math.PI / 2;
        this.updatePreview();
        this.updateStatusMessage();
      }
      event.preventDefault();
      return true;
    }

    // Manual angle input
    if (key === 'a') {
      if (this.state === 'setAngle') {
        const currentDegrees = Math.round(this.angle * 180 / Math.PI);
        const input = prompt(`Enter rotation angle (current: ${currentDegrees}°):`, currentDegrees);
        if (input !== null) {
          const degrees = parseFloat(input);
          if (!isNaN(degrees)) {
            this.angle = degrees * Math.PI / 180;
            this.updatePreview();
            this.updateStatusMessage();
            this.cad.render();
          }
        }
      }
      event.preventDefault();
      return true;
    }

    // Proceed to next step or apply
    if (key === 'enter' || key === ' ') {
      if (this.selectedObjects.length === 0) {
        return false;
      }

      if (this.state === 'selectObjects') {
        // Move to center selection
        this.state = 'selectCenter';
        this.updateStatusMessage();
      } else if (this.state === 'selectCenter') {
        // Use selection center
        this.useSelectionCenter();
      } else if (this.state === 'setAngle') {
        // Apply rotation
        this.applyRotation();
      }
      event.preventDefault();
      return true;
    }

    // Cancel / Back
    if (key === 'escape') {
      if (this.state === 'setAngle') {
        // Back to center selection
        this.state = 'selectCenter';
        this.centerPoint = null;
        this.angle = 0;
        this.previewObjects = [];
        this.updateStatusMessage();
        this.cad.render();
      } else if (this.state === 'selectCenter') {
        // Back to object selection
        this.state = 'selectObjects';
        this.updateStatusMessage();
      } else if (this.selectedObjects.length > 0) {
        // Clear selection
        this.clearSelection();
      }
      event.preventDefault();
      return true;
    }

    return false;
  }

  /**
   * Use center of selection as rotation center
   */
  useSelectionCenter() {
    const bounds = this.getSelectionBounds();
    this.centerPoint = {
      x: (bounds.minX + bounds.maxX) / 2,
      y: (bounds.minY + bounds.maxY) / 2
    };
    this.state = 'setAngle';
    this.angle = 0;
    this.updatePreview();
    this.updateStatusMessage();
    this.cad.render();
  }

  /**
   * Update preview objects
   */
  updatePreview() {
    this.previewObjects = [];

    if (this.selectedObjects.length === 0 || !this.centerPoint) {
      return;
    }

    // Rotate each selected object
    for (const obj of this.selectedObjects) {
      const rotated = this.rotateObject(obj, this.centerPoint, this.angle);
      if (rotated) {
        this.previewObjects.push(rotated);
      }
    }
  }

  /**
   * Rotate an object
   */
  rotateObject(obj, center, angle) {
    const rotated = { ...obj };
    delete rotated._rotateSelected;

    switch(obj.type) {
      case 'line':
        rotated.p1 = this.rotatePoint(obj.p1, center, angle);
        rotated.p2 = this.rotatePoint(obj.p2, center, angle);
        break;

      case 'rectangle':
        // Convert to 4 points, rotate, find new bounds
        const corners = [
          { x: obj.x, y: obj.y },
          { x: obj.x + obj.width, y: obj.y },
          { x: obj.x + obj.width, y: obj.y + obj.height },
          { x: obj.x, y: obj.y + obj.height }
        ];

        const rotatedCorners = corners.map(p => this.rotatePoint(p, center, angle));

        // Find new bounding box
        const minX = Math.min(...rotatedCorners.map(p => p.x));
        const minY = Math.min(...rotatedCorners.map(p => p.y));
        const maxX = Math.max(...rotatedCorners.map(p => p.x));
        const maxY = Math.max(...rotatedCorners.map(p => p.y));

        // Note: This converts rectangle to polyline for accurate rotation
        rotated.type = 'polyline';
        rotated.points = rotatedCorners;
        rotated.closed = true;
        break;

      case 'circle':
        const circleCenter = this.rotatePoint({ x: obj.cx, y: obj.cy }, center, angle);
        rotated.cx = circleCenter.x;
        rotated.cy = circleCenter.y;
        // Radius doesn't change
        break;

      case 'arc':
        const arcCenter = this.rotatePoint({ x: obj.cx, y: obj.cy }, center, angle);
        rotated.cx = arcCenter.x;
        rotated.cy = arcCenter.y;
        // Rotate the angles
        rotated.startAngle = obj.startAngle + angle;
        rotated.endAngle = obj.endAngle + angle;
        break;

      case 'polyline':
        rotated.points = obj.points.map(p => this.rotatePoint(p, center, angle));
        break;
    }

    return rotated;
  }

  /**
   * Rotate a point around center
   */
  rotatePoint(point, center, angle) {
    const cos = Math.cos(angle);
    const sin = Math.sin(angle);

    const dx = point.x - center.x;
    const dy = point.y - center.y;

    return {
      x: center.x + dx * cos - dy * sin,
      y: center.y + dx * sin + dy * cos
    };
  }

  /**
   * Apply rotation
   */
  applyRotation() {
    if (this.selectedObjects.length === 0 || !this.centerPoint) {
      return;
    }

    if (this.previewObjects.length === 0) {
      this.updatePreview();
    }

    // Remove originals if not keeping
    if (!this.keepOriginal) {
      for (const obj of this.selectedObjects) {
        delete obj._rotateSelected;
        this.cad.removeObject(obj);
      }
    } else {
      for (const obj of this.selectedObjects) {
        delete obj._rotateSelected;
      }
    }

    // Add rotated objects
    for (const obj of this.previewObjects) {
      this.cad.addObject(obj);
    }

    const degrees = Math.round(this.angle * 180 / Math.PI);
    this.cad.saveHistory();
    this.cad.setStatus(`ROTATE: Rotated ${this.previewObjects.length} object(s) by ${degrees}° | ${this.keepOriginal ? 'Kept' : 'Removed'} original(s)`);

    // Reset
    this.clearSelection();
    this.state = 'selectObjects';
    this.centerPoint = null;
    this.angle = 0;
    this.previewObjects = [];

    this.cad.render();
    this.updateStatusMessage();
  }

  /**
   * Clear selection
   */
  clearSelection() {
    for (const obj of this.selectedObjects) {
      delete obj._rotateSelected;
    }
    this.selectedObjects = [];
    this.previewObjects = [];
    this.updateStatusMessage();
    this.cad.render();
  }

  /**
   * Get selection bounds
   */
  getSelectionBounds() {
    let minX = Infinity, minY = Infinity;
    let maxX = -Infinity, maxY = -Infinity;

    for (const obj of this.selectedObjects) {
      const bounds = this.getObjectBounds(obj);
      minX = Math.min(minX, bounds.minX);
      minY = Math.min(minY, bounds.minY);
      maxX = Math.max(maxX, bounds.maxX);
      maxY = Math.max(maxY, bounds.maxY);
    }

    return { minX, minY, maxX, maxY };
  }

  /**
   * Get object bounds
   */
  getObjectBounds(obj) {
    let minX = Infinity, minY = Infinity;
    let maxX = -Infinity, maxY = -Infinity;

    const updateBounds = (x, y) => {
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x);
      maxY = Math.max(maxY, y);
    };

    switch(obj.type) {
      case 'line':
        updateBounds(obj.p1.x, obj.p1.y);
        updateBounds(obj.p2.x, obj.p2.y);
        break;
      case 'rectangle':
        updateBounds(obj.x, obj.y);
        updateBounds(obj.x + obj.width, obj.y + obj.height);
        break;
      case 'circle':
        updateBounds(obj.cx - obj.radius, obj.cy - obj.radius);
        updateBounds(obj.cx + obj.radius, obj.cy + obj.radius);
        break;
      case 'arc':
        updateBounds(obj.cx - obj.radius, obj.cy - obj.radius);
        updateBounds(obj.cx + obj.radius, obj.cy + obj.radius);
        break;
      case 'polyline':
        for (const p of obj.points) {
          updateBounds(p.x, p.y);
        }
        break;
    }

    return { minX, minY, maxX, maxY };
  }

  /**
   * Custom render
   */
  render(ctx) {
    if (!ctx) return;

    // Render preview objects (ghost)
    if (this.previewObjects.length > 0) {
      ctx.save();
      ctx.strokeStyle = '#4ec9b0';
      ctx.fillStyle = 'rgba(78, 201, 176, 0.1)';
      ctx.globalAlpha = 0.5;
      ctx.lineWidth = 2;
      ctx.setLineDash([5, 5]);

      for (const obj of this.previewObjects) {
        this.renderObject(ctx, obj);
      }

      ctx.restore();
    }

    // Render selected objects highlight
    for (const obj of this.selectedObjects) {
      if (obj._rotateSelected) {
        ctx.save();
        ctx.strokeStyle = '#569cd6';
        ctx.lineWidth = 3;
        ctx.globalAlpha = 0.7;
        ctx.setLineDash([]);

        this.renderObject(ctx, obj);

        ctx.restore();
      }
    }

    // Render center point
    if (this.centerPoint) {
      ctx.save();
      ctx.fillStyle = '#ff9900';
      ctx.strokeStyle = '#ff9900';
      ctx.lineWidth = 2;

      // Cross
      ctx.beginPath();
      ctx.moveTo(this.centerPoint.x - 10, this.centerPoint.y);
      ctx.lineTo(this.centerPoint.x + 10, this.centerPoint.y);
      ctx.moveTo(this.centerPoint.x, this.centerPoint.y - 10);
      ctx.lineTo(this.centerPoint.x, this.centerPoint.y + 10);
      ctx.stroke();

      // Circle
      ctx.beginPath();
      ctx.arc(this.centerPoint.x, this.centerPoint.y, 5, 0, Math.PI * 2);
      ctx.fill();

      ctx.restore();
    }

    // Render angle indicator (arc from center)
    if (this.state === 'setAngle' && this.centerPoint && Math.abs(this.angle) > 0.01) {
      ctx.save();
      ctx.strokeStyle = '#ff9900';
      ctx.lineWidth = 2;
      ctx.setLineDash([5, 3]);
      ctx.globalAlpha = 0.7;

      const radius = 50;
      ctx.beginPath();
      ctx.arc(this.centerPoint.x, this.centerPoint.y, radius, 0, this.angle, this.angle < 0);
      ctx.stroke();

      // Arrow at end
      const arrowX = this.centerPoint.x + Math.cos(this.angle) * radius;
      const arrowY = this.centerPoint.y + Math.sin(this.angle) * radius;
      ctx.fillStyle = '#ff9900';
      ctx.beginPath();
      ctx.arc(arrowX, arrowY, 4, 0, Math.PI * 2);
      ctx.fill();

      ctx.restore();
    }
  }

  /**
   * Render an object
   */
  renderObject(ctx, obj) {
    ctx.beginPath();

    switch(obj.type) {
      case 'line':
        ctx.moveTo(obj.p1.x, obj.p1.y);
        ctx.lineTo(obj.p2.x, obj.p2.y);
        ctx.stroke();
        break;

      case 'rectangle':
        ctx.rect(obj.x, obj.y, obj.width, obj.height);
        ctx.stroke();
        break;

      case 'circle':
        ctx.arc(obj.cx, obj.cy, obj.radius, 0, Math.PI * 2);
        ctx.stroke();
        break;

      case 'arc':
        ctx.arc(obj.cx, obj.cy, obj.radius, obj.startAngle, obj.endAngle);
        ctx.stroke();
        break;

      case 'polyline':
        if (obj.points && obj.points.length > 0) {
          ctx.moveTo(obj.points[0].x, obj.points[0].y);
          for (let i = 1; i < obj.points.length; i++) {
            ctx.lineTo(obj.points[i].x, obj.points[i].y);
          }
          if (obj.closed) {
            ctx.closePath();
          }
          ctx.stroke();
        }
        break;
    }
  }

  /**
   * Deactivate tool
   */
  deactivate() {
    this.clearSelection();
    this.centerPoint = null;
    this.angle = 0;
    this.previewObjects = [];
    this.isDragging = false;
    this.hoverPoint = null;
    this.dragStartPoint = null;
  }
}
