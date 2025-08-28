import { Component, NO_ERRORS_SCHEMA, OnInit, ViewChild, effect, inject, signal } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import { Page, SwipeGestureEventData, SwipeDirection, knownFolders, path } from '@nativescript/core'
import { ActivatedRoute, Router } from '@angular/router'
import { DownloadedFile } from '~/app/models/downloadedFile';

@Component({
  selector: 'ns-score',
  templateUrl: './score.component.html',
  styleUrl: './score.component.css',
  imports: [NativeScriptCommonModule, NativeScriptRouterModule],
  schemas: [NO_ERRORS_SCHEMA],
})
export class ScoreComponent implements OnInit {
  songs: DownloadedFile[] = [];
  currentIndex = 0;

  @ViewChild('imageRef', { static: true }) imageRef;
  constructor(private page: Page, private route: ActivatedRoute) { }

  ngOnInit(): void {
    this.currentIndex = +this.route.snapshot.params['id'];
    this.songs = JSON.parse(this.route.snapshot.queryParams['songs'] || '[]');
  }

  get scorePath(): string {
    const song = this.songs[this.currentIndex];
    if (!song) return '';

    const documents = knownFolders.documents();
    const instrumentFolder = documents.getFolder(song.instrument);
    return path.join(instrumentFolder.path, song.fileName);
  }

  onSwipe(args: SwipeGestureEventData) {
    if (args.direction === SwipeDirection.left) {
      if (this.currentIndex < this.songs.length - 1) {
        this.animateSwipe(-300); // hacia la izquierda
        this.currentIndex++;
      }
    } else if (args.direction === SwipeDirection.right) {
      if (this.currentIndex > 0) {
        this.animateSwipe(300); // hacia la derecha
        this.currentIndex--;
      }
    }
  }

  animateSwipe(translateX: number) {
    const image = this.imageRef.nativeElement; // referencia al <Image>
    image.animate({
      translate: { x: translateX, y: 0 },
      opacity: 0,
      duration: 200
    }).then(() => {
      // Reset posición para la nueva imagen
      image.translateX = -translateX;
      return image.animate({
        translate: { x: 0, y: 0 },
        opacity: 1,
        duration: 200
      });
    });
  }

  toggleVisibilityNav() {
    const newStatus = this.page.actionBar.visibility === 'visible' ? 'hidden' : 'visible'
    this.page.actionBar.visibility = newStatus
    if (newStatus === 'hidden') {
      this.page.actionBar.height = 0
    } else {
      this.page.actionBar.height = 44
    }
  }
}
