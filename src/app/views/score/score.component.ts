import { Component, NO_ERRORS_SCHEMA, OnInit, effect, inject, signal } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import { Page, SwipeGestureEventData, SwipeDirection } from '@nativescript/core'
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


  constructor(private page: Page, private route: ActivatedRoute) {}

  ngOnInit(): void {
    this.currentIndex = +this.route.snapshot.params['id'];
    this.songs = JSON.parse(this.route.snapshot.queryParams['songs'] || '[]');
  }

  get scorePath(): string {
    return this.songs[this.currentIndex]?.localPath || '';
  }

  onSwipe(args: SwipeGestureEventData) {
    if (args.direction === SwipeDirection.left) {
      // Siguiente
      if (this.currentIndex < this.songs.length - 1) {
        this.currentIndex++;
      }
    } else if (args.direction === SwipeDirection.right) {
      // Anterior
      if (this.currentIndex > 0) {
        this.currentIndex--;
      }
    }
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
