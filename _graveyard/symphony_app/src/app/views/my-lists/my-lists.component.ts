import {
  Component,
  NO_ERRORS_SCHEMA,
  OnInit,
  inject,
  signal,
} from "@angular/core";
import {
  NativeScriptCommonModule,
  NativeScriptRouterModule,
  RouterExtensions,
} from "@nativescript/angular";
import { getString } from "@nativescript/core/application-settings";
import { SongList } from "../../models/songList";
import { SongListsService } from "../../services/song-lists.service";
import { prompt, confirm } from "@nativescript/core/ui/dialogs";
import { CollectionViewModule } from "@nativescript-community/ui-collectionview/angular";
import { install } from "@nativescript-community/ui-collectionview-swipemenu";
import { Router } from "@angular/router";
import { Dialogs, Page } from "@nativescript/core";
import { InstrumentsService } from "~/app/services/instruments.service";

install();

@Component({
  moduleId: module.id,
  selector: "ns-my-lists",
  templateUrl: "my-lists.component.html",
  styleUrls: ["my-lists.component.css"],
  imports: [
    NativeScriptCommonModule,
    NativeScriptRouterModule,
    CollectionViewModule,
  ],
  schemas: [NO_ERRORS_SCHEMA],
})
export class MyListsComponent {
  constructor(
    public service: SongListsService,
    private router: Router,
    private instrumentService: InstrumentsService,
    private routerExtensions: RouterExtensions
  ) {}

  goBack(): void {
    this.routerExtensions.backToPreviousPage();
  }
  async addList() {
    const newList = await prompt({
      title: "Nueva Lista",
      message: "Ingrese el título de la nueva lista:",
      okButtonText: "Confirmar",
      cancelButtonText: "Cancelar",
      defaultText: `Lista ${this.service.myLists().length + 1}`,
      inputType: "text",
    });

    if (!newList.result) {
      return;
    }
    const newName = newList.text.trim();
    const canContinue = this.checkIfExists(newName);
    if (!canContinue) {
      return;
    }

    const instrument = await this.selectInstrument();
    console.log("instrumetn... ", instrument);
    if (instrument === "Cancelar") {
      return;
    }

    this.service.createList(newName, instrument);
  }

  async selectInstrument() {
    const instruments = this.instrumentService.instruments();
    const options = instruments.map((i) => i.path);

    return await Dialogs.action({
      title: "Instrumento",
      cancelButtonText: "Cancelar",
      actions: options,
      cancelable: true,
    });
  }

  async removeList(i) {
    const { name } = this.service.myLists()[i];
    const isConfirmed = await confirm(`Desea eliminar la lista: ${name}`);
    if (!isConfirmed) return;

    this.service.removeList(i);
  }

  async checkIfExists(name: string) {
    try {
      const i = this.service.myLists().findIndex((s) => s.name.trim() === name);
      if (i === -1) {
        return true;
      }

      const isConfirmed = await confirm(
        `Ya existe una lista con el nombre: ${name}. ¿Desea sobreescribirla?`
      );
      return isConfirmed;
    } catch (error) {
      true;
    }
  }

  goToDetails(item: SongList) {
    this.router.navigate(["/myLists", item.name]);
  }
}
