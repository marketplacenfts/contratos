Inicializar nodo local con hardhat

Despues de clonar el repositorio cambiarse a la carpeta contratos/ y correr el siguiente comando

$npx hardhat node

En otra terminal cambiarse al directorio contratos/ y correr el siguiente comando para compilar y deployar en la red local creada por hardhat

$npx hardhat run scripts/deploy.js --network localhost

Copiar las direcciones al compilar y deployar el contrato para copiarlas en el archivo config.js de la carpeta frontend-market
