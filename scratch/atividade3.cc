/*
Esta atividade consiste em aplicar mobilidade em cada nó implementado no cenário da atividade 2. Para isso, o aluno deverá reutilizar a implementação da atividade 2 e realizar os seguintes modificações:

    1. Cada nó deve se mover a uma velocidade constante ao longo do eixo X da esquerda para a direita;
    2. Modificar a aplicação dos nós de modo que:
        a. A cada 5 segundos, o nó N4 deve definir aleatoriamente seu novo valor de velocidade entre [2, 8]m/s e enviar uma mensagem (M) com esse valor para o vizinho N3. Ao receber M, N3 define sua nova velocidade e encaminha M para o próximo vizinho N2. O procedimento se repete até M alcançar N0 o qual define sua nova velocidade.
*/

#include "ns3/core-module.h"             // Módulo central do NS-3 (simulação de eventos, logs, etc.)
#include "ns3/network-module.h"          // Módulo para abstrações de rede
#include "ns3/internet-module.h"         // Módulo para pilha de protocolos TCP/IP
#include "ns3/wifi-module.h"             // Módulo para simulações WiFi
#include "ns3/mobility-module.h"         // Módulo para configurar mobilidade dos nós
#include "ns3/applications-module.h"     // Módulo para criar aplicações na simulação
#include <netinet/in.h>                  // Biblioteca padrão para conversão de ordem de bytes
#include <random>                        // Biblioteca para geração de números aleatórios
#include "ns3/netanim-module.h"

using namespace ns3;
#define NUM_NODES 5                      // Define o número de nós na simulação

NS_LOG_COMPONENT_DEFINE("Atividade3");   // Define o componente de log para "Atividade3"

/*
    Fluxo de comunicaçao:

    NO -> N1 -> N2 -> N3 -> N4
    N4 -> N3 -> N2 -> N1 -> N0
    N0 -> N1 -> N2 -> N3 -> N4
    N4 -> N3 -> N2 -> N1 -> N0
    N0 -> N1 -> N2 -> N3 -> N4
    ...
    
    Ou seja:

    N0:
        Recebe o valor.
        Sempre imprime o valor recebido.
        Gera um número aleatório e envia para N1.

    N1:
        Sempre imprime o valor recebido.
    	Sempre encaminham o valor recebido:
            De N0 para N2 (se veio do menor).
            De N2 para N0 (se veio do maior).

    N2:
    	Sempre imprime o valor recebido.
    	Sempre encaminham o valor recebido:
            De N1 para N3 (se veio do menor).
            De N3 para N1 (se veio do maior).
    N3:
    	Sempre imprime o valor recebido.
        Sempre encaminham o valor recebido:
            De N2 para N4 (se veio do menor).
            De N4 para N2 (se veio do maior).

    N4:
        Recebe o valor.
        Sempre imprime o valor recebido.
        Gera um novo número e envia para N3.

    Duração: 30s
 */

// Função para gerar números aleatórios
int GenerateRandomValue() {

    static std::random_device rd;                       // Semente para o gerador de números aleatórios
    static std::mt19937 gen(rd());                      // Gerador Mersenne Twister
    static std::uniform_int_distribution<> dis(0, 100); // Distribuição uniforme no intervalo [0, 100]

    return dis(gen);                                   // Retorna um número aleatório
}

// Gera velocidade entre 2-8 m/s
int GenerateRandomSpeed() {

    static std::random_device rd;
    static std::mt19937 gen(rd());
    static std::uniform_int_distribution<> dis(2, 8);

    return dis(gen);
}

// Classe TcpApp: representa a aplicação para cada nó na rede TCP
class TcpApp : public Application {

    public:

        TcpApp();                                         // Construtor
        virtual ~TcpApp();                                // Destrutor

        static TypeId GetTypeId (void);                  // Retorna o TypeId da aplicação
        void ConfigureApplication (int id,Ptr<Node> node,Ptr<Socket> data_sender_socket,Ptr<Socket> data_receiver_socket,Ptr<Socket> speed_sender_socket,Ptr<Socket> speed_receiver_socket,Ipv4Address left_neighbor_ip,Ipv4Address right_neighbor_ip,bool generator);

        void StartApplication() override;                // Sobrescreve a inicialização da aplicação
        void StopApplication() override;                 // Sobrescreve o encerramento da aplicação

        // Callbacks para conexões e recepção de pacotes
        void SendDataPacket (int32_t number);               // Envia pacotes para um vizinho
        void ProcessDataPacket (Ptr<Socket> socket);
        void EstablishDataNeighborLink (Ipv4Address neighbor_address);
        void HandleDataConnectionAccept (Ptr<Socket> socket, const Address& from);
        
        void ConnectionSucceeded(Ptr<Socket> socket);
        void ConnectionFailed(Ptr<Socket> socket);
        bool ValidateConnection(Ptr<Socket> socket, const Address& from);       

        void SendSpeedPacket (int32_t number);
        void SendSpeedUpdate();               // Envia atualizações de velocidade
        void ProcessSpeedPacket(Ptr<Socket> socket); // Processa pacotes de velocidade
        void EstablishSpeedNeighborLink (Ipv4Address neighbor_address);
        void HandleSpeedConnectionAccept (Ptr<Socket> socket, const Address& from);

        // Variaveis
        int id;                                         // Índice do nó
        Ptr<Node> node;                                 // Nó associado à aplicação
        bool generator;                                 // Indica se o nó é gerador de número
        Ipv4Address right_neighbor_ip;                  // Endereço IP do vizinho direito
        Ipv4Address left_neighbor_ip;                   // Endereço IP do vizinho esquerdo

        Ptr<Socket> data_sender_socket;                      // Socket para enviar pacotes
        Ptr<Socket> data_receiver_socket;                    // Socket para receber pacotes
        uint16_t data_port = 8080;                           // Porta de recepção

        Ptr<Socket> speed_sender_socket;
        Ptr<Socket> speed_receiver_socket;
        uint16_t speed_port = 8081; // Porta separada para mensagens de velocidade

};

// Construtor da aplicação
TcpApp::TcpApp() {
    data_sender_socket = 0;
    data_receiver_socket = 0;
    speed_sender_socket = 0;
    speed_receiver_socket = 0;
    generator = false;
}

// Destrutor da aplicação
TcpApp::~TcpApp() {
    data_sender_socket = 0;
    data_receiver_socket = 0;
    speed_sender_socket = 0;
    speed_receiver_socket = 0;
}

/// Registra o TypeId da aplicação
TypeId TcpApp::GetTypeId(void) {

    static TypeId tid = TypeId("TcpApp")
        .SetParent<Application>()      // Define como uma subclasse de Application
        .AddConstructor<TcpApp>();     // Permite a criação de objetos da classe
    return tid;
}

// Configuração inicial da aplicação
void TcpApp::ConfigureApplication(int id,Ptr<Node> node,Ptr<Socket> data_sender_socket,Ptr<Socket> data_receiver_socket,Ptr<Socket> speed_sender_socket,Ptr<Socket> speed_receiver_socket,Ipv4Address left_neighbor_ip,Ipv4Address right_neighbor_ip,bool generator = false) {
    
    this->id = id;
    this->node = node;
    this->data_sender_socket = data_sender_socket;
    this->data_receiver_socket = data_receiver_socket;
    this->speed_sender_socket = speed_sender_socket;
    this->speed_receiver_socket = speed_receiver_socket;
    this->right_neighbor_ip = right_neighbor_ip;
    this->left_neighbor_ip = left_neighbor_ip;
    this->generator = generator;
}

// Método chamado ao iniciar a aplicação
void TcpApp::StartApplication(void) {

    // Criação de sockets para envio e recepção de pacotes
    Ptr<Socket> data_receiver_socket = Socket::CreateSocket (this->node, TcpSocketFactory::GetTypeId ());
    Ptr<Socket> data_sender_socket = Socket::CreateSocket (this->node, TcpSocketFactory::GetTypeId ());

    // Configuração do socket receptor
    InetSocketAddress local = InetSocketAddress(Ipv4Address::GetAny(), data_port);
    if (data_receiver_socket->Bind(local) == -1) {
      NS_FATAL_ERROR("Not found socket");
    }
    data_receiver_socket->Listen();
    data_receiver_socket->SetAcceptCallback(
      MakeCallback(&TcpApp::ValidateConnection, this),
      MakeCallback(&TcpApp::HandleDataConnectionAccept, this)
    );

    this->data_receiver_socket = data_receiver_socket;
    this->data_sender_socket = data_sender_socket;



    // Criação de sockets para envio e recepção de pacotes
    Ptr<Socket> speed_receiver_socket = Socket::CreateSocket (this->node, TcpSocketFactory::GetTypeId ());
    Ptr<Socket> speed_sender_socket = Socket::CreateSocket (this->node, TcpSocketFactory::GetTypeId ());

    // Configuração do socket receptor
    InetSocketAddress speed_local = InetSocketAddress(Ipv4Address::GetAny(), speed_port);
    if (speed_receiver_socket->Bind(speed_local) == -1) {
      NS_FATAL_ERROR("Not found socket");
    }
    speed_receiver_socket->Listen();
    speed_receiver_socket->SetAcceptCallback(
      MakeCallback(&TcpApp::ValidateConnection, this),
      MakeCallback(&TcpApp::HandleSpeedConnectionAccept, this)
    );

    this->speed_receiver_socket = speed_receiver_socket;
    this->speed_sender_socket = speed_sender_socket;

    // Conecta imediatamente ao vizinho esquerdo para velocidade
    if (id != 0) { // N1, N2, N3, N4 conectam ao vizinho esquerdo
        EstablishSpeedNeighborLink(this->left_neighbor_ip);
    }

    // O primeiro nó (N0) gera e envia o primeiro número
    if (this->id == 0) {
        int32_t number =  GenerateRandomValue();
        EstablishDataNeighborLink(this->left_neighbor_ip);
        SendDataPacket(number);
    }

    // Agendar atualizações de velocidade apenas para N4
    if (this->id == 4) {
        Simulator::Schedule(Seconds(5.0), &TcpApp::SendSpeedUpdate, this);
    }
}

// Método chamado ao encerrar a aplicação
void TcpApp::StopApplication(void) {

    if (this->data_receiver_socket) {
        this->data_receiver_socket->Close();
        this->data_receiver_socket = nullptr;
    }

    if (this->data_sender_socket) {
        this->data_sender_socket->Close();
        this->data_sender_socket = nullptr;
    }

    if (this->speed_receiver_socket) {
        this->speed_receiver_socket->Close();
        this->speed_receiver_socket = nullptr;
    }

    if (this->speed_sender_socket) {
        this->speed_sender_socket->Close();
        this->speed_sender_socket = nullptr;
    }

    NS_LOG_UNCOND("Fim da aplicação");
}



// Envia um pacote com o número fornecido
void TcpApp::SendDataPacket(int32_t number) {  
    
    int32_t networkOrderNumber = htonl(number);
    Ptr<Packet> packet = Create<Packet>((uint8_t *)&networkOrderNumber, sizeof(networkOrderNumber));
    this->data_sender_socket->Send(packet);
    data_sender_socket->Close();
    
    NS_LOG_INFO("Nó "<< this->id << " enviou " << number);
}

// Callback chamado ao receber um pacote
void TcpApp::ProcessDataPacket(Ptr<Socket> socket) {

    Address from;                        // Endereço do remetente do pacote
    Ptr<Packet> packet;                  // Ponteiro para o pacote recebido
    int32_t networkOrderNumber;          // Número no formato de ordem de rede
    int32_t receivedNumber = 0;          // Número recebido (convertido para ordem do host)

    // Cria um novo socket para envio
    Ptr<Socket> data_sender_socket = Socket::CreateSocket(this->node, TcpSocketFactory::GetTypeId());
    this->data_sender_socket = data_sender_socket;

    // Processa todos os pacotes recebidos
    while ((packet = socket->RecvFrom(from))) {
        if (packet->GetSize() == 0) break; // Se o pacote estiver vazio, interrompe o loop

        // Converte o endereço do remetente para InetSocketAddress para obter o IP
        InetSocketAddress inetFrom = InetSocketAddress::ConvertFrom(from);

        // Extrai o número do pacote
            // Copia os dados do pacote para a variável networkOrderNumber
        packet->CopyData((uint8_t *)&networkOrderNumber, sizeof(networkOrderNumber));
        receivedNumber = ntohl(networkOrderNumber); // Converte para ordem do host

        // Lógica original para números normais (Atividade 2)
        NS_LOG_UNCOND("Nó " << this->id << " recebeu: " << receivedNumber);

        // Se for extremidade (gerador), cria novo número
        if (this->generator) {
            receivedNumber = GenerateRandomValue();
            EstablishDataNeighborLink(this->left_neighbor_ip);
        } 
        else {
            // Decide para qual vizinho encaminhar
            if (this->right_neighbor_ip == inetFrom.GetIpv4()) {
                EstablishDataNeighborLink(this->left_neighbor_ip);
            } else {
                EstablishDataNeighborLink(this->right_neighbor_ip);
            }
        }

        // Envia o número processado
        SendDataPacket(receivedNumber);
    }
}

// Conecta a um nó vizinho
void TcpApp::EstablishDataNeighborLink(Ipv4Address neighbor_address) {

    this->data_sender_socket->SetConnectCallback (
        MakeCallback(&TcpApp::ConnectionSucceeded, this),
        MakeCallback(&TcpApp::ConnectionFailed, this)
    );

    InetSocketAddress remote = InetSocketAddress(neighbor_address, this->data_port);
    this->data_sender_socket->Connect(remote);
    NS_LOG_INFO("Nó "<< this->id << " conectou com " << neighbor_address);
}

// Callback chamado quando uma conexão é aceita
void TcpApp::HandleDataConnectionAccept(Ptr<Socket> socket, const Address& from) {
    socket->SetRecvCallback(MakeCallback(&TcpApp::ProcessDataPacket, this));
}



// Callback para conexão bem-sucedida
void TcpApp::ConnectionSucceeded(Ptr<Socket> socket) {
    NS_LOG_INFO("Conexão bem-sucedida");
}

// Callback para falha de conexão
void TcpApp::ConnectionFailed(Ptr<Socket> socket) {
    NS_LOG_INFO("Falha na conexão");
}

// Callback para solicitações de conexão
bool TcpApp::ValidateConnection(Ptr<Socket> socket, const Address& from) {
    NS_LOG_INFO("Conexão solicitada de: " << from);
    return true;
}



// Envia pacote de velocidade
void TcpApp::SendSpeedPacket(int32_t speed) {
    int32_t networkOrderSpeed = htonl(speed);
    Ptr<Packet> packet = Create<Packet>((uint8_t *)&networkOrderSpeed, sizeof(networkOrderSpeed));
    if (speed_sender_socket->Send(packet) == -1) {
        NS_LOG_ERROR("Falha ao enviar pacote de velocidade");
    } else {
        NS_LOG_INFO("Nó " << this->id << " enviou " << speed);
    }
}

// Envia atualização de velocidade (chamado por N4 a cada 5s)
void TcpApp::SendSpeedUpdate() {
    int new_speed = GenerateRandomSpeed();
    NS_LOG_UNCOND("Nó " << id << " definiu velocidade: " << new_speed << " m/s");

    Ptr<ConstantVelocityMobilityModel> mob = node->GetObject<ConstantVelocityMobilityModel>();
    if (mob) {
        mob->SetVelocity(Vector(new_speed, 0.0, 0.0));
    }
    
    SendSpeedPacket(new_speed);
    
    // Agenda próxima atualização
    Simulator::Schedule(Seconds(5.0), &TcpApp::SendSpeedUpdate, this);
}

// Processa pacote de velocidade recebido
void TcpApp::ProcessSpeedPacket(Ptr<Socket> socket) {
    Address from;
    Ptr<Packet> packet;
    int32_t networkOrderSpeed;
    int32_t receivedSpeed;

    // Cria um novo socket para envio
    Ptr<Socket> speed_sender_socket = Socket::CreateSocket(this->node, TcpSocketFactory::GetTypeId());
    this->speed_sender_socket = speed_sender_socket;
    
    while ((packet = socket->RecvFrom(from))) {
        
        if (packet->GetSize() == 0) break;

        // Extrai a velocidade
        packet->CopyData((uint8_t *)&networkOrderSpeed, sizeof(networkOrderSpeed));
        receivedSpeed = ntohl(networkOrderSpeed);

        // Atualiza a velocidade do nó
        NS_LOG_UNCOND("Nó " << id << " atualizou velocidade para " << receivedSpeed << " m/s");

        Ptr<ConstantVelocityMobilityModel> mob = node->GetObject<ConstantVelocityMobilityModel>();
        if (mob) {
            mob->SetVelocity(Vector(receivedSpeed, 0.0, 0.0));
        }

        // Encaminha para o próximo nó (exceto N0)
        if (id != 0) {
            EstablishSpeedNeighborLink(left_neighbor_ip);
            SendSpeedPacket(receivedSpeed);
        }
    }
}

// Conecta ao vizinho esquerdo (para velocidade)
void TcpApp::EstablishSpeedNeighborLink(Ipv4Address neighbor_address) {

    this->speed_sender_socket->SetConnectCallback (
        MakeCallback(&TcpApp::ConnectionSucceeded, this),
        MakeCallback(&TcpApp::ConnectionFailed, this)
    );

    InetSocketAddress remote = InetSocketAddress(neighbor_address, this->speed_port);
    speed_sender_socket->Connect(remote);
    NS_LOG_INFO("Nó "<< this->id << " conectou com " << neighbor_address);
}

// Callback chamado quando uma conexão é aceita
void TcpApp::HandleSpeedConnectionAccept(Ptr<Socket> socket, const Address& from) {
    socket->SetRecvCallback(MakeCallback(&TcpApp::ProcessSpeedPacket, this));
}


void PrintVelocidades(NodeContainer nodes) {
    for (uint32_t i = 0; i < nodes.GetN(); i++) {
        Ptr<ConstantVelocityMobilityModel> mob = nodes.Get(i)->GetObject<ConstantVelocityMobilityModel>();
        if (mob) {
            Vector velocidade = mob->GetVelocity();
            NS_LOG_UNCOND("Nó " << i << " tem velocidade atual: " << velocidade.x << " m/s");
        }
    }
    Simulator::Schedule(Seconds(5.0), &PrintVelocidades, nodes);
}


int main(int argc, char *argv[]) {

    //LogComponentEnable("Atividade3", LOG_LEVEL_INFO);  // Habilita NS_LOG_INFO para "Atividade3"
    
    CommandLine cmd; // Adicione esta linha
    cmd.Parse(argc, argv); // Permite usar --vis na execução
    
    // Cria nós
    NodeContainer nodes;
    nodes.Create(5);

    // Configuração de WiFi
    WifiHelper wifi;
    YansWifiChannelHelper channel = YansWifiChannelHelper::Default();
    YansWifiPhyHelper phy;
    phy.SetChannel(channel.Create());
    WifiMacHelper mac;
    mac.SetType("ns3::AdhocWifiMac");
    NetDeviceContainer devices = wifi.Install(phy, mac, nodes);

    // Configurar mobilidade com velocidade constante
    MobilityHelper mobility;
    mobility.SetPositionAllocator("ns3::GridPositionAllocator",
                                "MinX", DoubleValue(0.0),
                                "MinY", DoubleValue(0.0),
                                "DeltaX", DoubleValue(5.0),
                                "DeltaY", DoubleValue(0.0),
                                "GridWidth", UintegerValue(NUM_NODES),
                                "LayoutType", StringValue("RowFirst"));
    mobility.SetMobilityModel("ns3::ConstantVelocityMobilityModel");
    mobility.Install(nodes);

    // Definir velocidade inicial para 2 m/s em todos os nós
    for (uint32_t i = 0; i < nodes.GetN(); ++i) {
        Ptr<ConstantVelocityMobilityModel> mob = nodes.Get(i)->GetObject<ConstantVelocityMobilityModel>();
        if (mob) {
            mob->SetVelocity(Vector(2.0, 0.0, 0.0));
        }
    }

    // Instalar pilha TCP/IPv4
    InternetStackHelper stack;
    stack.Install(nodes);

    // Configurar endereços IP
    Ipv4AddressHelper address;
    address.SetBase("10.0.0.0", "255.0.0.0");
    Ipv4InterfaceContainer interfaces = address.Assign(devices);

    // Configurar sockets para cada nó
    for (int i = 0; i < NUM_NODES; i++) {
        Ptr<TcpApp> application = CreateObject<TcpApp>();
        if (i == 0) {
            // Configuração para o nó 0
            application->ConfigureApplication(i, nodes.Get(i), nullptr, nullptr, nullptr, nullptr, interfaces.GetAddress(i + 1), interfaces.GetAddress(i + 1), true);
        } else if (i == NUM_NODES - 1) {
            // Configuração para o último nó
            application->ConfigureApplication(i, nodes.Get(i), nullptr, nullptr, nullptr, nullptr, interfaces.GetAddress(i - 1), interfaces.GetAddress(i - 1), true);
        } else {
            // Configuração para os nós intermediários
            application->ConfigureApplication(i, nodes.Get(i), nullptr, nullptr, nullptr, nullptr, interfaces.GetAddress(i - 1), interfaces.GetAddress(i + 1), false);
        }
        application->SetStartTime(Seconds(1.));
        application->SetStopTime(Seconds(30));
        nodes.Get(i)->AddApplication(application);
    }

    AnimationInterface anim("atividade3.xml"); // Arquivo de saída do NetAnim
    anim.SetMaxPktsPerTraceFile(10000000);
    Simulator::Stop(Seconds(30));
    // PrintVelocidades(nodes);
    Simulator::Run();
    Simulator::Destroy();

    return 0;
}