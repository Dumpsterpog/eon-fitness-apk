@echo off
REM Builds a release APK you can install on any Android phone.
REM Requires Flutter 3.29+ and the Android SDK (Android Studio installs it).
cd /d "%~dp0"

call flutter create --platforms=android --org com.atharva --project-name eon_fitness . || goto :error
call flutter pub get || goto :error
call flutter build apk --release || goto :error

copy /Y build\app\outputs\flutter-apk\app-release.apk EonFitness.apk >nul
echo.
echo Done: %cd%\EonFitness.apk
echo Copy it to your phone and open it, or run: flutter install
goto :eof

:error
echo Build failed. Run "flutter doctor" to check your setup.
exit /b 1
