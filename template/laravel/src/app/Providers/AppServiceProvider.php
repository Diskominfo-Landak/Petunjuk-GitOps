<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Paksa skema HTTPS jika APP_URL menggunakan HTTPS atau di lingkungan non-lokal (mencegah Mixed Content)
        if (str_starts_with((string) config('app.url'), 'https://') || ! app()->environment('local')) {
            URL::forceScheme('https');
        }
    }
}
