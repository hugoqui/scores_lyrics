import { Component, NO_ERRORS_SCHEMA, OnInit, inject } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import { Page, Label } from '@nativescript/core'
import { prompt } from "@nativescript/core/ui/dialogs";
import * as appSettings from '@nativescript/core/application-settings';
import { Router } from "@angular/router";

import { SocketIO } from '@triniwiz/nativescript-socketio';

@Component({
  moduleId: module.id,
  selector: 'ns-home',
  templateUrl: 'home.component.html',
  styleUrls: ['home.component.css'],
  imports: [NativeScriptCommonModule, NativeScriptRouterModule,],
  schemas: [NO_ERRORS_SCHEMA],
})
export class HomeComponent {
  page = inject(Page)

  constructor(private router: Router) {
    this.page.on('loaded', (args) => {
      if (__IOS__) {
        const navigationController: UINavigationController = this.page.frame.ios.controller
        navigationController.navigationBar.prefersLargeTitles = true
      }
    })
  }  

  async setHost(): Promise<void> {
    try {
      // this.router.navigate(['/menu']);
      // return
      
      console.log('setting host...')
      let host = appSettings.getString('host', 'http://192.168.5.1:3014');
   
      const newHost = await prompt({
        title: 'Servidor',
        message: 'Ingrese el url del servidor:',
        okButtonText: 'Confirmar',
        cancelButtonText: 'Cancelar',
        defaultText: host,
        inputType: 'text',
        capitalizationType: 'none'
      })

      console.log('newost', newHost)
      if (!newHost.result) { return }

      appSettings.setString('host', newHost.text);
      this.router.navigate(['/menu']);

    } catch (error) {
      console.log('error setting host...', error)
    }
  }

  goToSettings() {
    try {
      console.log('navigating to settings...')
      this.router.navigate(['/settings']);      
    } catch (error) {
      console.log('error navigating to settings...', error)
    }
  }
}