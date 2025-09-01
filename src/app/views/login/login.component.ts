import { Component, OnInit, NO_ERRORS_SCHEMA, signal, AfterViewInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { AuthService } from '../../services/auth.service';
import { Page } from '@nativescript/core';
import { NativeScriptCommonModule, NativeScriptRouterModule, RouterExtensions } from '@nativescript/angular'
import { getString, } from "@nativescript/core/application-settings";

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css'],
  imports: [NativeScriptCommonModule, NativeScriptRouterModule,],
  schemas: [NO_ERRORS_SCHEMA],
})
export class LoginComponent implements OnInit, AfterViewInit {
  loginForm: FormGroup;
  isLoading = signal<boolean>(false);
  errorMessage = '';
  componentBuilded = signal(false);

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private routerExtensions: RouterExtensions,
    private page: Page
  ) {
    this.loginForm = this.fb.group({
      email: ['', Validators.required],
      password: ['', Validators.required]
    });
  }



  ngOnInit(): void {
    this.page.actionBarHidden = true;
    if (this.authService.isAuthenticated()) {
      this.routerExtensions.navigate(['/home'], { clearHistory: true });

      return
    }

    this.loginForm.value.email = getString('email', '');
    this.loginForm.value.password = getString('password', '');
  }

  ngAfterViewInit(): void {
    setTimeout(() => {
      this.componentBuilded.set(true);
    }, 100);
  }

  onSubmit() {
    if (this.loginForm.invalid) {
      this.markFormGroupTouched(this.loginForm);
      return;
    }

    this.isLoading.set(true);
    this.errorMessage = '';

    const { email, password } = this.loginForm.value;
    console.log('sendin..', email)

    this.authService.login(email, password).subscribe({
      next: (result) => {
        this.isLoading.set(false);
        if (result.success) {
          this.routerExtensions.navigate(['/home'], { clearHistory: true });
        } else {
          this.errorMessage = result.message || 'Credenciales incorrectas';
        }
      },
      error: (error) => {
        this.isLoading.set(false);
        this.errorMessage = 'Error en el servidor. Intente nuevamente.';
        console.error('Login error:', error);
      }
    });

  }

  private markFormGroupTouched(formGroup: FormGroup) {
    Object.values(formGroup.controls).forEach(control => {
      control.markAsTouched();

      if (control instanceof FormGroup) {
        this.markFormGroupTouched(control);
      }
    });
  }
}
