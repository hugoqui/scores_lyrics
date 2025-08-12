import { Routes } from '@angular/router';
import { HomeComponent } from './views/home/home.component';
import { MenuComponent } from './views/menu/menu.component';
import { SettingsComponent } from './views/settings/settings.component';
import { LiveComponent } from './views/live/live.component';
import { ScoreListComponent } from './views/score-list/score-list.component';
import { ScoreComponent } from './views/score/score.component';
import { DownloadScoresComponent } from './views/download-scores/download-scores.component';

export const routes: Routes = [
  { path: '', redirectTo: '/home', pathMatch: 'full' },
  // { path: '', redirectTo: '/download-scores/1', pathMatch: 'full' },
  { path: 'home', component:  HomeComponent },
  { path: 'menu/:menuPath', component:  MenuComponent },
  { path: 'live/:id', component:  LiveComponent },
  
  { path: 'practice/:instrumentId', component:  ScoreListComponent },
  { path: 'score/:id', component:  ScoreComponent },
  { path: 'download-scores/:id', component: DownloadScoresComponent },
  
  { path: 'settings', component: SettingsComponent },

];
