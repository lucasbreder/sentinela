/// Tipo de placa de veículo.
///
/// Usado para restringir os caracteres de cada posição durante a extração e
/// para priorizar um padrão (Mercosul vs antiga) em vez de gerar candidatos
/// para os dois ao mesmo tempo, reduzindo as opções apresentadas ao usuário.
enum PlateType {
  /// Placa Mercosul: `ABC1D23` (faixa azul no topo).
  mercosul,

  /// Placa antiga (cinza): `ABC1234`.
  old,

  /// Tipo não identificado (padrão). Sem restrição de padrão.
  unknown,
}
