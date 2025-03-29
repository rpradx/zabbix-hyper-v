# Monitoramento Hyper-V

---

## Índice
1. [Visão Geral](#visão-geral)
2. [Recursos](#recursos)
3. [Requisitos](#requisitos)
4. [Instalação](#instalação)
5. [Configuração](#configuração)
6. [Uso](#uso)

---

## 1. Visão Geral

Este projeto integra o Zabbix à plataforma de virtualização Microsoft Hyper-V, permitindo o monitoramento de hosts e máquinas virtuais através do Zabbix.

---

## 2. Features

**Descoberta Automatizada:** Detecta automaticamente os hosts Hyper-V e suas máquinas virtuais, facilitando a inclusão de novos dispositivos no monitoramento.
**Monitoramento Abrangente:** Acompanha métricas de desempenho tanto dos hosts Hyper-V quanto das suas máquinas virtuais, garantindo insights precisos sobre a saúde dos ambientes.
**Coleta Eficiente de Dados:** Utiliza um script PowerShell robusto para coletar e retornar informações detalhadas e em tempo real.

---

## 3. Requisitos

- **Zabbix Server:** Versão 7 ou mais recente.
- **Sistema Operacional:** Windows Server com a função Hyper-V habilitada.
- **Permissões:** Acesso adequado para consultar as métricas do Hyper-V.

---

## 4. Instalação

1. **Copie** o arquivo `zbx-hyperv.ps1` para o diretório:  
   `C:\Program Files\Zabbix Agent\scripts`
2. **Importe** o arquivo `zbx-hyperv-template.yaml` no seu Zabbix Server.
3. **Importe** o arquivo `Monitor Hyper-V.json` no Grafana, se desejar um dashboard pré-configurado.

---

## 5. Configuração

Adicione os seguintes **UserParameter** no arquivo de configuração do `zabbix_agent`:

```bash
### Option: UserParameter
# Parâmetro definido pelo usuário para monitoramento.
# Formato: UserParameter=<chave>,<comando shell>
#
# Exemplo:
UserParameter=hyperv.lld,powershell -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\scripts\zbx-hyperv.ps1" lld
UserParameter=hyperv.full,powershell -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\scripts\zbx-hyperv.ps1" full
UserParameter=hyperv.count,powershell -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\scripts\zbx-hyperv.ps1" count
```

---

## 6. Uso

O script pode ser executado diretamente no PowerShell ou via agente Zabbix.

### Execução Direta

Navegue até o diretório onde o script está localizado e utilize a seguinte sintaxe:

```powershell
.\zbx-hyperv.ps1 [opções]
```

Exemplos:

PS C:\Program Files\Zabbix Agent\scripts> .\zbx-hyperv.ps1 full  
Retorna um JSON com informações detalhadas de cada VM:
```json
{"New Virtual Machine":{"IsClustered":0,"ReplMode":0,"Uptime":16390585,"ReplState":0,"StartAction":3,"NumaSockets":1,"IntSvcVer":"0.0","Disks":{"Path":"C:\\Users\\Public\\Documents\\Hyper-V\\Virtual Hard Disks\\New Virtual Machine.vhdx","FileSize":4194304,"Size":16106127360},"NumaNodes":1,"ProcessorCount":4,"IntSvcState":2,"State":2,"CritErrAction":1,"ReplHealth":0,"StopAction":3,"CPUUsage":0,"MemoryUsage":0,"Memory":4294967296,"NetworkInterfaces":{"Status":"NoContact","Name":"Network Adapter","IPAddresses":"","MacAddress":"00155DFC6301"}}}
```

PS C:\Program Files\Zabbix Agent\scripts> .\zbx-hyperv.ps1 lld  
Retorna um JSON para descoberta automática (LLD):
```json
{"data":[{"{#VM.NAME}":"New Virtual Machine","{#VM.ID}":"37a31433-6c28-4bba-8be0-0d4905f29834","{#VM.VERSION}":"9.0","{#VM.CLUSTERED}":0,"{#VM.HOST}":"WIN-1234569","{#VM.GEN}":1,"{#VM.ISREPLICA}":0,"{#VM.NOTES}":""}]}
```

PS C:\Program Files\Zabbix Agent\scripts> .\zbx-hyperv.ps1 count  
Retorna um JSON com a contagem de VMs online, offline e total:
```json
{"OfflineVMs":0,"TotalVMs":1,"OnlineVMs":1}
```

### Exemplos de Uso

- Para obter a descoberta automática das VMs:
    ```powershell
    .\zbx-hyperv.ps1 lld
    ```
- Para exibir as informações detalhadas de cada VM:
    ```powershell
    .\zbx-hyperv.ps1 full
    ```
- Para visualizar a contagem de VMs:
    ```powershell
    .\zbx-hyperv.ps1 count
    ```