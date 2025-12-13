import { Component, Input, ViewChild, ElementRef, NO_ERRORS_SCHEMA, Output, EventEmitter } from '@angular/core';
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular';
import { PinchGestureEventData, PanGestureEventData, Image } from '@nativescript/core';

@Component({
  selector: 'ns-zoom-image',
  standalone: true,  
  templateUrl: './zoom-image.component.html',
  imports: [NativeScriptCommonModule, NativeScriptRouterModule],  
  schemas: [NO_ERRORS_SCHEMA],
})
export class ZoomImageComponent {
  @Input() src: string;
  @Output() tap = new EventEmitter<void>(); 

  @ViewChild('img', { static: true }) imgRef: ElementRef<Image>;

  private scale = 1;
  private lastScale = 1;
  private startX = 0;
  private startY = 0;

  onPinch(event: PinchGestureEventData) {
    if (event.state === 1) { // comienzo
      this.lastScale = this.scale;
    } else if (event.state === 2) { // cambiando
      this.scale = Math.max(1, Math.min(this.lastScale * event.scale, 5)); // limita entre 1x y 5x
      const img = this.imgRef.nativeElement;
      img.scaleX = this.scale;
      img.scaleY = this.scale;
    }
  }

  onPan(event: PanGestureEventData) {
    if (this.scale <= 1) return; // solo mover si está ampliada

    const img = this.imgRef.nativeElement;

    if (event.state === 1) { // comienzo
      this.startX = img.translateX;
      this.startY = img.translateY;
    } else if (event.state === 2) { // moviendo
      img.translateX = this.startX + event.deltaX;
      img.translateY = this.startY + event.deltaY;
    }
  }

  onTap() {
    this.tap.emit(); 
  }

}
