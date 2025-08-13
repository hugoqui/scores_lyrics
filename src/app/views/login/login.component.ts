import { Component, OnInit, NO_ERRORS_SCHEMA, signal, AfterViewInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { Page } from '@nativescript/core';
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'

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
    private router: Router,
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
      this.router.navigate(['/home']);
    }
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

    this.authService.login(email, password).subscribe({
      next: (success) => {
        this.isLoading.set(false);
        if (success) {
          this.router.navigate(['/home']);
        } else {
          this.errorMessage = 'Credenciales incorrectas';
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
