/// A versão de um conteúdo novo. A versão de um documento editado vem do
/// conteúdo dele (`requiredSpecVersion`): a 2 só quando há `$bind`/`$theme`,
/// para que uma página sem formas novas continue legível por app antigo.
const int kSpecVersion = 1;

const int kOldestSpecVersion = 1;

const int kLatestSpecVersion = 2;

const int kTypedPropValuesSpecVersion = 2;
