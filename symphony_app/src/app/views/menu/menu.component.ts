import { Component, NO_ERRORS_SCHEMA, inject, signal } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule, RouterExtensions } from '@nativescript/angular'
import { Page, Label, knownFolders } from '@nativescript/core'
import { InstrumentsService } from '../../services/instruments.service'
import { ActivatedRoute, Router } from '@angular/router'
@Component({
  selector: 'ns-menu',
  templateUrl: './menu.component.html',
  styleUrl: './menu.component.css',
  imports: [NativeScriptCommonModule, NativeScriptRouterModule],
  schemas: [NO_ERRORS_SCHEMA],
})
export class MenuComponent {
  constructor(
    private page: Page,
    public instrumentsService: InstrumentsService,
    private route: ActivatedRoute,
    private router: Router,
    private routerExtensions: RouterExtensions
  ) {

  }

  menuPath = signal<string>('');

  goBack(): void {
    this.routerExtensions.backToPreviousPage();
  }
  ngOnInit() {
    this.menuPath.set(this.route.snapshot.params.menuPath)
    console.log('##### menupath', this.menuPath())
  }

  navigateTo(id: string) {
    try {
      console.log('Navigating to:', id);
      this.router.navigate([`/${this.menuPath()}`, id]);
    } catch (error) {
      console.error('Navigation error:', error);
    }
  }

  getDownloadsLength(instrumentPath: string): number {
    try {
      const documents = knownFolders.documents();
      const instrumentFolder = documents.getFolder(instrumentPath);
      return instrumentFolder.getEntitiesSync().length;
    } catch (error) {
      return 0
    }
  }

}
