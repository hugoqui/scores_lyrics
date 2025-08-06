import { Component, NO_ERRORS_SCHEMA, inject } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import { Page, Label } from '@nativescript/core'
import {InstrumentsService} from '../../services/instruments.service'
@Component({
  selector: 'ns-menu',
  templateUrl: './menu.component.html',
  styleUrl: './menu.component.css',
  imports: [NativeScriptCommonModule, NativeScriptRouterModule],
  schemas: [NO_ERRORS_SCHEMA],
})
export class MenuComponent {
  constructor(private page: Page, public instrumentsService: InstrumentsService) {
    
  }

  ngOnInit() {
    console.log(this.instrumentsService.instrumetns());
  }

}
