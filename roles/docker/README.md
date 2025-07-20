# Docker Role

Esta role é responsável pela instalação e configuração do Docker em sistemas Ubuntu.

## Funcionalidades

- Instalação da chave GPG do Docker
- Configuração do repositório oficial do Docker
- Instalação do Docker CE
- Configuração do usuário no grupo docker
- Configuração do serviço Docker para inicialização automática
- Suporte para login em registries Docker

## Variáveis

### Variáveis opcionais (defaults/main.yml)

```yaml
# docker_registry_username: your_username
# docker_registry_password: your_password
# docker_registry_url: docker.io
```

## Tags

- `docker`: Tarefas relacionadas à instalação do Docker
- `services`: Tarefas relacionadas à configuração de serviços
- `registry`: Tarefas relacionadas ao login no registry
- `molecule-notest`: Tarefas que são puladas durante os testes do Molecule

## Dependências

Esta role requer:
- Sistema operacional Ubuntu
- Acesso à internet para download de pacotes
- Privilégios de root para instalação

## Exemplo de uso

```yaml
- hosts: servers
  become: yes
  roles:
    - docker
  vars:
    docker_registry_username: myuser
    docker_registry_password: mypassword
    docker_registry_url: docker.io
```

## Testes

Para executar os testes com Molecule:

```bash
cd roles/docker
molecule test
```
