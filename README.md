# Entorno de desarrollo en vivo
`npm run dev`

# Construir para producción
`npm run build`

# Previsualizar versión de producción
`npm run preview`

# Sincronizar app(s) nativa(s) tras construir
`npx cap sync`

# Abrir app(s) nativa(s) para compilación
`npx cap open android` (Requiere Android Studio y el NDK instalados)

`npx cap open ios` (Requiere Xcode y el paquete de compilación de iOS)

Nota: Aunque posible, actualmente no he añadido iOS a la lista de objetivos. Se puede hacer con lo siguiente:

`npm i @capacitor/ios`

`npx cap add ios`
