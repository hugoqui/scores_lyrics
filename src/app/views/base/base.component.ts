import { Component, NO_ERRORS_SCHEMA, OnInit, inject } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'

@Component({
  moduleId: module.id,
  selector: 'ns-base',
  templateUrl: 'base.component.html',
  styleUrls: ['base.component.css'],
  imports: [NativeScriptCommonModule, NativeScriptRouterModule,],
  schemas: [NO_ERRORS_SCHEMA],
})
export class BaseComponent {


}