/**
 * Fillet Tool - Fusion 360 Style
 * Raccorda angoli con archi di raggio specificato
 *
 * @module FilletTool
 * @author Box Designer CAD Engine
 */

export class FilletTool {
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'fillet';
    this.radius = 5; // Default 5mm
    this.firstLine = null;
    this.secondLine = null;
    this.previewArc = null;
    this.hoverLine = null;
  }

  activate() {
    this.firstLine = null;
    this.secondLine = null;
    this.previewArc = null;
    this.hoverLine = null;
    this.cad.setStatus(`FILLET: Select first line (Radius: ${this.radius}mm) | Press R to change radius`);
  }

  setRadius(radius) {
    this.radius = Math.abs(parseFloat(radius) || 5);
    this.updateStatusMessage();
  }

  updateStatusMessage() {
    if (!this.firstLine) {
      this.cad.setStatus(`FILLET: Select first line (Radius: ${this.radius}mm) | Press R to change radius`);
    } else {
      this.cad.setStatus(`FILLET: Select second line (Radius: ${this.radius}mm)`);
    }
  }

  onClick(point, event) {
    const object = this.cad.getObjectAt(point);

    if (!object || object.type !== 'line') {
      this.cad.setStatus(`FILLET: Select a line (Radius: ${this.radius}mm)`);
      return;
    }

    if (!this.firstLine) {
      this.firstLine = object;
      this.firstLine._filletHighlight = true; // Mark for highlight
      this.updateStatusMessage();
      this.cad.render();
      return;
    }

    this.secondLine = object;

    // Crea fillet
    const result = this.createFillet(this.firstLine, this.secondLine, this.radius);

    if (result) {
      // Clear highlight
      delete this.firstLine._filletHighlight;

      // Rimuovi linee originali e aggiungi nuove
      this.cad.removeObject(this.firstLine);
      this.cad.removeObject(this.secondLine);

      result.objects.forEach(obj => this.cad.addObject(obj));

      this.cad.saveHistory();
      this.cad.render();
      this.cad.setStatus(`FILLET: Created with radius ${this.radius}mm | Press R to change radius`);
    } else {
      // Clear highlight
      delete this.firstLine._filletHighlight;
      this.cad.setStatus('FILLET: Cannot create fillet - lines may be parallel or radius too large');
      this.cad.render();
    }

    this.firstLine = null;
    this.secondLine = null;
    this.previewArc = null;
  }

  /**
   * Crea fillet tra due linee
   * @param {Object} line1 - Prima linea
   * @param {Object} line2 - Seconda linea
   * @param {number} radius - Raggio fillet
   * @returns {Object|null} {objects: [...], arc: {...}}
   */
  createFillet(line1, line2, radius) {
    // Trova intersezione
    const intersection = this.findIntersection(line1, line2);

    if (!intersection) {
      // Lines are parallel or don't intersect
      return null;
    }

    // Calcola centro arco fillet
    const center = this.calculateFilletCenter(line1, line2, intersection, radius);

    if (!center) {
      // Radius too large or angle too small
      return null;
    }

    // Verify center is valid (not NaN or Infinity)
    if (!isFinite(center.x) || !isFinite(center.y)) {
      return null;
    }

    // Calcola punti tangenti su line1 e line2
    const tangent1 = this.calculateTangentPoint(line1, center, radius);
    const tangent2 = this.calculateTangentPoint(line2, center, radius);

    // Verify tangent points are valid
    if (!isFinite(tangent1.x) || !isFinite(tangent1.y) ||
        !isFinite(tangent2.x) || !isFinite(tangent2.y)) {
      return null;
    }

    // Check if tangent points are within reasonable distance of intersection
    const maxDist = radius * 10; // Safety check
    const dist1 = Math.hypot(tangent1.x - intersection.x, tangent1.y - intersection.y);
    const dist2 = Math.hypot(tangent2.x - intersection.x, tangent2.y - intersection.y);

    if (dist1 > maxDist || dist2 > maxDist) {
      // Radius likely too large for these lines
      return null;
    }

    // Calcola angoli per arco
    let startAngle = Math.atan2(tangent1.y - center.y, tangent1.x - center.x);
    let endAngle = Math.atan2(tangent2.y - center.y, tangent2.x - center.x);

    // Ensure arc goes the short way
    if (endAngle - startAngle > Math.PI) {
      endAngle -= 2 * Math.PI;
    } else if (startAngle - endAngle > Math.PI) {
      startAngle -= 2 * Math.PI;
    }

    // Crea arco fillet
    const arc = {
      type: 'arc',
      lineType: line1.lineType || 'cut',
      cx: center.x,
      cy: center.y,
      radius: radius,
      startAngle: startAngle,
      endAngle: endAngle
    };

    // Trimma linee ai punti tangenti
    const trimmedLine1 = this.trimLine(line1, tangent1);
    const trimmedLine2 = this.trimLine(line2, tangent2);

    return {
      objects: [trimmedLine1, trimmedLine2, arc],
      arc: arc
    };
  }

  /**
   * Trova intersezione tra due linee (anche estese)
   */
  findIntersection(line1, line2) {
    const x1 = line1.p1.x, y1 = line1.p1.y;
    const x2 = line1.p2.x, y2 = line1.p2.y;
    const x3 = line2.p1.x, y3 = line2.p1.y;
    const x4 = line2.p2.x, y4 = line2.p2.y;

    const denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if (Math.abs(denom) < 1e-10) return null;

    const t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom;

    return {
      x: x1 + t * (x2 - x1),
      y: y1 + t * (y2 - y1)
    };
  }

  /**
   * Calcola centro arco fillet
   */
  calculateFilletCenter(line1, line2, intersection, radius) {
    // Vettori direzione normalizzati
    const v1 = this.normalize({ x: line1.p2.x - line1.p1.x, y: line1.p2.y - line1.p1.y });
    const v2 = this.normalize({ x: line2.p2.x - line2.p1.x, y: line2.p2.y - line2.p1.y });

    // Vettore bisettrice
    const bisector = this.normalize({ x: v1.x + v2.x, y: v1.y + v2.y });

    // Angolo tra linee
    const angle = Math.acos(v1.x * v2.x + v1.y * v2.y);
    const distance = radius / Math.sin(angle / 2);

    return {
      x: intersection.x + bisector.x * distance,
      y: intersection.y + bisector.y * distance
    };
  }

  /**
   * Normalizza vettore
   */
  normalize(v) {
    const len = Math.sqrt(v.x * v.x + v.y * v.y);
    return { x: v.x / len, y: v.y / len };
  }

  /**
   * Calcola punto tangente su linea
   */
  calculateTangentPoint(line, center, radius) {
    // Proietta centro perpendicolarmente sulla linea
    const dx = line.p2.x - line.p1.x;
    const dy = line.p2.y - line.p1.y;

    const fx = line.p1.x - center.x;
    const fy = line.p1.y - center.y;

    const t = -(fx * dx + fy * dy) / (dx * dx + dy * dy);

    return {
      x: line.p1.x + t * dx,
      y: line.p1.y + t * dy
    };
  }

  /**
   * Trimma linea al punto
   */
  trimLine(line, point) {
    // Determina quale estremo è più vicino al punto
    const dist1 = Math.hypot(point.x - line.p1.x, point.y - line.p1.y);
    const dist2 = Math.hypot(point.x - line.p2.x, point.y - line.p2.y);

    if (dist1 < dist2) {
      return { ...line, p1: point };
    } else {
      return { ...line, p2: point };
    }
  }

  onMove(point, event) {
    // Hover feedback
    const object = this.cad.getObjectAt(point);
    this.hoverLine = (object && object.type === 'line') ? object : null;

    // Preview fillet if first line selected
    if (this.firstLine && this.hoverLine && this.hoverLine !== this.firstLine) {
      const previewResult = this.createFillet(this.firstLine, this.hoverLine, this.radius);
      this.previewArc = previewResult ? previewResult.arc : null;
    } else {
      this.previewArc = null;
    }

    this.cad.render();
  }

  onKeyDown(event) {
    // R key - change radius
    if (event.key.toLowerCase() === 'r') {
      const newRadius = prompt(`Enter fillet radius (current: ${this.radius}mm):`, this.radius);
      if (newRadius !== null) {
        this.setRadius(newRadius);
      }
      event.preventDefault();
      return true;
    }

    // ESC - cancel first line selection
    if (event.key === 'Escape' && this.firstLine) {
      delete this.firstLine._filletHighlight;
      this.firstLine = null;
      this.previewArc = null;
      this.updateStatusMessage();
      this.cad.render();
      event.preventDefault();
      return true;
    }

    return false;
  }

  render(ctx) {
    // Render preview arc (ghost)
    if (this.previewArc) {
      ctx.save();
      ctx.strokeStyle = '#4ec9b0';
      ctx.globalAlpha = 0.5;
      ctx.lineWidth = 2;
      ctx.setLineDash([5, 5]);

      ctx.beginPath();
      ctx.arc(
        this.previewArc.cx,
        this.previewArc.cy,
        this.previewArc.radius,
        this.previewArc.startAngle,
        this.previewArc.endAngle
      );
      ctx.stroke();

      ctx.restore();
    }

    // Highlight first selected line
    if (this.firstLine && this.firstLine._filletHighlight) {
      ctx.save();
      ctx.strokeStyle = '#4ec9b0';
      ctx.lineWidth = 3;
      ctx.globalAlpha = 0.7;

      ctx.beginPath();
      ctx.moveTo(this.firstLine.p1.x, this.firstLine.p1.y);
      ctx.lineTo(this.firstLine.p2.x, this.firstLine.p2.y);
      ctx.stroke();

      ctx.restore();
    }

    // Highlight hover line
    if (this.hoverLine && this.hoverLine !== this.firstLine) {
      ctx.save();
      ctx.strokeStyle = '#569cd6';
      ctx.lineWidth = 2;
      ctx.globalAlpha = 0.5;

      ctx.beginPath();
      ctx.moveTo(this.hoverLine.p1.x, this.hoverLine.p1.y);
      ctx.lineTo(this.hoverLine.p2.x, this.hoverLine.p2.y);
      ctx.stroke();

      ctx.restore();
    }
  }

  deactivate() {
    if (this.firstLine) {
      delete this.firstLine._filletHighlight;
    }
    this.firstLine = null;
    this.secondLine = null;
    this.previewArc = null;
    this.hoverLine = null;
  }
}
