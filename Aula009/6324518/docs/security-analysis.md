# Análise de Segurança da Infraestrutura

A arquitetura deste projeto foi desenhada seguindo o **Princípio do Menor Privilégio**, garantindo que recursos sejam expostos apenas quando estritamente necessário.

### Segurança de Rede (Security Groups)
O Security Group da instância web (`WebServer-SG`) atua como um firewall virtual stateful.
* **Porta 80 (HTTP):** Aberta para `0.0.0.0/0` (qualquer IP) para permitir o acesso público ao portfólio.
* **Porta 22 (SSH):** Restrita estritamente ao endereço IP dinâmico do desenvolvedor (`/32`), mitigando ataques de força bruta globais automatizados.

### Isolamento de Recursos
A infraestrutura utiliza o conceito de VPC (Virtual Private Cloud) para segmentação.
* **Subnet Pública:** Destinada apenas a recursos que precisam de acesso à internet, como o servidor Nginx, através de um Internet Gateway.
* **Subnet Privada:** Isolada da internet externa, ideal para futuras implementações de bancos de dados nativos (como RDS), que se comunicarão apenas com as instâncias da Subnet Pública.