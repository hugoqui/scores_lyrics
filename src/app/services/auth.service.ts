import { HttpClient } from '@angular/common/http';
import { getString, setString, clear } from "@nativescript/core/application-settings";
import { Injectable, signal } from '@angular/core';
import { Router } from "@angular/router";
import { catchError, map, Observable, of } from 'rxjs';
import { getUUID } from 'nativescript-uuid-v2';

@Injectable({
    providedIn: 'root',
})
export class AuthService {

    private apiUrl = 'https://api.iglesiacristianabelen.com/api/login';

    constructor(private http: HttpClient, private router: Router) { }

    login(username: string, password: string): Observable<boolean> {
        setString('token', '');

        const deviceUUID = getUUID();
        console.log(`El UUID del dispositivo es: ${deviceUUID}`);

        return this.http
            .post<any>(this.apiUrl, { email: username, password: password, device: deviceUUID })
            .pipe(
                map(response => {
                    console.log('Login successful', response);
                    setString('token', response.token);
                    // Guardar la fecha de expiración del token 60 días a partir de ahora
                    setString('expiration', new Date(Date.now() + (60 * 24 * 60 * 60 * 1000)).toISOString());
                    return true;
                }),
                catchError(error => {
                    console.error('Login failed', error);
                    return of(false);
                })
            );
    }

    isAuthenticated(): boolean {
        // return false
        if (!getString('token')) {
            return false;
        }

        const expiration = getString('expiration');
        if (!expiration) {
            return false;
        }

        const expirationDate = new Date(expiration);
        return new Date() < expirationDate;
    }
}

