# Iniciar Procesos de Aprobación

- Si modificas algún tipo de sito, referencia elara, o producto de
oportunidad; y el expediente de proyecto está cerrado, entonces se deben
evitar las modificaciones en dichos registros. La única excepción para poder
realizar la modificación en el expediente de proyecto o en alguno de los
subregistros asociados es que exista un proceso de cambios iniciado.

- Para iniciar un proceso de aprobación se necesita hacerlo desde el
componente de lightning.

- No puede haber más de un proceso de aprobación por cuenta, si ya existe un
proceso, mandar un mensaje de error.


Todo debe partir del proceso de aprobación, una vez iniciado, se identifican los registros involucrados gracias al expediente de proyecto

Una vez iniciado, cada modicicacion a un registro debe crear  su propio contorl de aprobación en el before update