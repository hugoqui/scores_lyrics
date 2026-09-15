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

    login(username: string, password: string): Observable<{ success: boolean, message?: string }> {
        setString('token', '');

        const deviceUUID = getUUID();
        console.log(`El UUID del dispositivo es: ${deviceUUID}`);

        return this.http.post<any>(this.apiUrl, { email: username, password, device: deviceUUID }).pipe(
            map(response => {
                setString('email', username);
                setString('password', password);
                setString('token', response.token);
                //30 días para pedirle credenciales
                setString('expiration', new Date(Date.now() + (30 * 24 * 60 * 60 * 1000)).toISOString());
                return { success: true };
            }),
            catchError(error => {
                const errMsg = error?.error?.message || 'Error desconocido';
                return of({ success: false, message: errMsg });
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

