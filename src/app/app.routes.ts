import { Routes } from '@angular/router';
import { ItemsComponent } from './components/item/items.component';
import { HomeComponent } from './views/home/home.component';
import { MenuComponent } from './views/menu/menu.component';
import { SettingsComponent } from './views/settings/settings.component';
import { ScoreComponent } from './views/score/score.component';
import { ItemDetailComponent } from './components/item/item-detail.component';

export const routes: Routes = [
  { path: '', redirectTo: '/home', pathMatch: 'full' },
  { path: 'home', component:  HomeComponent },
  { path: 'menu', component:  MenuComponent },
  { path: 'score/:id', component:  ScoreComponent },
  
  { path: 'settings', component: SettingsComponent },

  { path: 'items', component: ItemsComponent },
  { path: 'item/:id', component: ItemDetailComponent },
];
