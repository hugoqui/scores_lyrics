import { Component, NO_ERRORS_SCHEMA, AfterViewInit, ViewChild, ElementRef } from '@angular/core';
import { PageRouterOutlet } from '@nativescript/angular';
import { isAndroid, Screen } from '@nativescript/core';

@Component({
  selector: 'ns-app',
  templateUrl: './app.component.html',
  imports: [PageRouterOutlet],
  schemas: [NO_ERRORS_SCHEMA],
})
export class AppComponent implements AfterViewInit {
  @ViewChild('root', { static: true }) root!: ElementRef;

  ngAfterViewInit(): void {
    if (!isAndroid) { return; }
    try {
      const resources = (<any>android).content.res.Resources.getSystem();
      const resourceId = resources.getIdentifier('navigation_bar_height', 'dimen', 'android');
      if (resourceId) {
        const navBarPx = resources.getDimensionPixelSize(resourceId);
        const navBarDp = navBarPx / Screen.mainScreen.scale;
        const rootView: any = this.root.nativeElement;
        // aplica padding bottom en dp para dejar espacio a la barra de navegación
        rootView.paddingBottom = navBarDp;
      }
    } catch (e) {
      console.log('error leyendo navigation_bar_height', e);
    }
  }
}
