#include "utils.h"
#include "ns3/flysafe-statistics.h"
#include <time.h>

namespace ns3 {

/**
 * @brief Get the Start Time Of Simulation
 * 
 * @return string - simulation start time string
 */
string
GetTimeOfSimulationStart()
{
	time_t now = time(0);
    tm *ltm = localtime(&now);
    ostringstream convert;

    if (ltm->tm_mday < 10)
    	convert << "0";
    convert << ltm->tm_mday;

    if ((ltm->tm_mon+1) < 10)
       	convert << "0";
    convert << ltm->tm_mon + 1;

    convert << 1900 + ltm->tm_year << "_" ;

    if (ltm->tm_hour < 10)
    	convert << "0";
    convert << ltm->tm_hour;

    if (ltm->tm_min < 10)
    	convert << "0";
    convert << ltm->tm_min << endl<< endl;

	return convert.str();
}

/**
 * @brief Create a Sim Scenario File
 * 
 * @param fileName - File name
 * @param simulDate - Simulation time
 * @param dataToSave - Simulation data
 */
void
CreateSimScenarioFile (string fileName, string simulDate, string dataToSave)
{
  ofstream fileSimRec;
  fileSimRec.open (fileName.c_str ());
  fileSimRec << "**** FlySafe scenario configuration file ****" << endl << endl;
  fileSimRec << "Date: " << simulDate.substr (0, 8).c_str () << " - "
             << simulDate.substr (9, 2).c_str () << ":" << simulDate.substr (11, 2).c_str () << "hs"
             << endl
             << endl;

  fileSimRec << dataToSave.c_str ();

  // Close scenario simulation configuration file
  fileSimRec << "**** End of FlySafe scenario configuration file ****" << endl;
  fileSimRec.close ();
}

/**
 * @brief Check whether positions are diferent 
 * @date Mar 5, 2023
 * 
 * @param oldPosition - Vector with old position
 * @param newPosition - Vector with new position
 * @return true - Different positions
 * @return false - Same position
 */

/**
 * @brief Check whether node position is changed
 * 
 * @param oldPosition - Old position
 * @param newPosition - Actual position
 * @return true - Actual position diferent from the old one
 * @return false - Stopped node
 */
bool
isPositionChanged (Vector oldPosition, Vector newPosition)
{
  return (oldPosition.x != newPosition.x) || (oldPosition.y != newPosition.y) || (oldPosition.z != newPosition.z);
}

/**
 * @brief Calculate distance between two nodes
 * 
 * @date Jan2023
 * 
 * @param myPosition Vector with node position
 * @param neighPosition Vector with neighbor node position
 * @return double Distance
 */

double CalculateNodesDistance(Vector myPosition, Vector neighPosition) {
  double hDistance;
  hDistance = sqrt(pow(myPosition.x - neighPosition.x, 2) + pow(myPosition.y - neighPosition.y, 2) * 1.0);
  return sqrt(pow(hDistance, 2) + pow(myPosition.z - neighPosition.z, 2) * 1.0);
}

/**
 * @brief Print a received neighbor list recovred from a tag
 * @date Feb 26, 2023
 */

void PrintNeighborList(std::vector<ns3::MyTag::NeighInfos> neighInfos) {

  for(auto n :neighInfos){
    cout << n.ip << " : Position x: " << n.x << " y: " << n.y << " z: " << n.z << " hop: " << (int)n.hop << endl;
  }
  cout << "\n" << endl;
}


/**
 * @brief Print received information about a malicous node
 * @date Nov 02, 2023
 */

void PrintMaliciousNodeInfo(std::vector<ns3::MyTag::NeighInfos> neighInfos) {

  cout << "Information received about a malicious node:" << endl;
  for(auto n :neighInfos){
    cout << n.ip << " : Position x: " << n.x << " y: " << n.y << " z: " << n.z << " hop: " << (int)n.hop << endl;
  }
  cout << "\n" << endl;
}

/**
 * @brief Generate false location data
 * @date Oct 30, 2023
 * 
 * @return Vector - Vector with location coordinates (x, y, z)
 */
Vector 
GenerateFalseLocation()
{
  Vector falseLocation;
  
  std::default_random_engine rnd{std::random_device{}()};
  std::uniform_real_distribution<double> fX(0, 1500);
  std::uniform_real_distribution<double> fY(0, 1500);
  std::uniform_real_distribution<double> fZ(91, 91);
  
  falseLocation.x = fX(rnd);
  falseLocation.y = fY(rnd);
  falseLocation.z = fZ(rnd);

  return falseLocation;
}

/**
 * @brief Generate malicious nodes
 * @date Nov 15, 2023
 * 
 * @return vector - vector with malicious nodes
 */
std::vector<int> 
GenerateMaliciousNodes(int nNodes, int nMalicious) {
    std::vector<int> numbers;
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, nNodes-1);
    int num;

    //cout << "Generating " << nMalicious << " malicious nodes:" << endl;
    for (int i = 0; i < nMalicious; i++) {
        num = dis(gen);
        while (std::find(numbers.begin(), numbers.end(), num) != numbers.end()) {
            num = dis(gen);
        }
        numbers.push_back(num);
        //cout << "Node: " << num << endl;
    }
    std::sort(numbers.begin(), numbers.end());
    return numbers;
}

/**
 * @brief Convert a vector with integers to a string separated by commas
 * 
 * @param vec - Int vector
 * @return std::string - String separated by commas
 */
std::string 
convertIntVectorToString(const std::vector<int>& vec) {
    std::stringstream ss;
    for (size_t i = 0; i < vec.size(); i++) {
        ss << vec[i];
        if (i != vec.size() - 1) {
            ss << ",";
        }
    }
    return ss.str();
}


/**
 * @brief Convert a vector with IPs to a string separated by commas
 * 
 * @date Nov 23, 2023
 * 
 * @param vec - IPv4 vector
 * @return std::string - String separated by commas
 */
std::string 
convertIPVectorToString(const std::vector<ns3::Ipv4Address>& vec) {
    std::stringstream ss;
    for (size_t i = 0; i < vec.size(); i++) {
        ss << vec[i];
        if (i != vec.size() - 1) {
            ss << ", ";
        }
    }
    return ss.str();
}

/**
 * @author Vinicius - MiM
 * 
 * @brief Execute a MiM attack by spoofing the packet with a false location
 * 
 * @note This function is called when the sniffer node is in the coverage area of the sender and receiver.
 * 
 * @param snifferNode - Pointer to the sniffer node
 * @param packet - Pointer to the captured packet
 * @param snifferIp - IP address of the sniffer node
 * @param senderIp - IP address of the sender node
 * @param receiverIp - IP address of the receiver node
 * @param originalTag - Tag containing the original position and other information
 * @param senderPosition - Position of the sender node
 */
void
ExecuteMiMAttack(Ptr<Node> snifferNode, Ptr<const Packet> packet, 
                Ipv4Address snifferIp, Ipv4Address senderIp, Ipv4Address receiverIp, 
                MyTag originalTag, Vector senderPosition) {

    // Copy the original packet to create a forged packet
    Ptr<Packet> forgedPacket = packet->Copy();

    // Remove the original headers from the forged packet
    WifiMacHeader wifiMacHeader;
    forgedPacket->RemoveHeader(wifiMacHeader);

    LlcSnapHeader llcSnapHeader;
    bool hasLlc = forgedPacket->PeekHeader(llcSnapHeader);
    if (hasLlc) {
        forgedPacket->RemoveHeader(llcSnapHeader);
    } else {
        llcSnapHeader.SetType(0x0800); // Default type for IPv4
    }

    Ipv4Header ipv4Header;
    forgedPacket->RemoveHeader(ipv4Header);
    
    UdpHeader udpHeader;
    forgedPacket->RemoveHeader(udpHeader);

    WifiMacTrailer trailer;
    forgedPacket->RemoveTrailer(trailer);

    // Generate false location
    Vector forgedPosition = GenerateFalseLocation();

    // Create a new tag with the forged position
    MyTag forgedTag = originalTag; 
    forgedTag.SetPosition(forgedPosition); 
    forgedPacket->ReplacePacketTag(forgedTag); 

    // Find the sniffer's wifinetdevice
    Ptr<WifiNetDevice> snifferDevice = nullptr;
    for (uint32_t i = 0; i < snifferNode->GetNDevices(); ++i) {
        Ptr<NetDevice> device = snifferNode->GetDevice(i);
        snifferDevice = DynamicCast<WifiNetDevice>(device);
        if (snifferDevice) {
            break;
        }
    }

    // Get the MAC layer of the sniffer device
    Ptr<AdhocWifiMac> mac = DynamicCast<AdhocWifiMac>(snifferDevice->GetMac());
    NS_ASSERT(mac != nullptr);

    // Set the forged packet's headers
    forgedPacket->AddHeader(udpHeader);
    forgedPacket->AddHeader(ipv4Header);
    forgedPacket->AddHeader(llcSnapHeader);

    // Set the forged MAC header
    WifiMacHeader forgedHdr;
    forgedHdr.SetType(WIFI_MAC_DATA);  
    forgedHdr.SetAddr1(wifiMacHeader.GetAddr1());
    forgedHdr.SetAddr2(wifiMacHeader.GetAddr2());
    forgedHdr.SetAddr3(wifiMacHeader.GetAddr3()); 
    forgedHdr.SetDsNotFrom();
    forgedHdr.SetDsNotTo();
    forgedHdr.SetNoRetry(); 

    // Enqueue the forged packet with the forged MAC header
    mac->GetTxop()->Queue(forgedPacket, forgedHdr);

    // Print the MiM attack information
    double timeNow = Simulator::Now().GetSeconds();
    cout << snifferIp << " : " << timeNow << " MiM - Spoofing packet to " << receiverIp 
            << ". Original Sender: " << senderIp << " - Real position: (" << senderPosition.x << ", " 
            << senderPosition.y << ", " << senderPosition.z << ") - " << "Fake position: (" 
            << forgedPosition.x << ", " << forgedPosition.y << ", " << forgedPosition.z << ")" << endl << endl;

}

/**
 * @author Vinicius - MiM
 * 
 * @brief Extracts the necessary information from the packet and calls the statistics callback. 
 *      If the sniffer node is in the coverage area of the sender and receiver, 
 *      it also executes a MiM attack by spoofing the packet with a false location.
 * 
 * @note This function is called when a packet is received by the sniffer. 
 * 
 * @param stats - Pointer to Statistics object
 * @param snifferNode - Pointer to the sniffer node
 * @param context - Context string
 * @param packet - Pointer to the received packet
 * @param channelFreqMhz - Frequency of the channel in MHz
 * @param txvector - WifiTxVector object containing transmission parameters
 * @param mpdu - MpduInfo object containing MPDU information
 * @param snr - SignalNoiseDbm object containing signal and noise information
 * @param staId - Station ID
 */
void 
ProcessSniffedPacket(Statistics* stats, Ptr<Node> snifferNode,
                       std::string context, Ptr<const Packet> packet,
                       uint16_t channelFreqMhz, WifiTxVector txvector,
                       MpduInfo mpdu, SignalNoiseDbm snr, uint16_t staId) {

    Ptr<Packet> snifferPacket = packet->Copy();

    // Extract the MAC header from the packet
    WifiMacHeader macHeader;
    if (snifferPacket->RemoveHeader(macHeader)) {
        
        // If the packet is a data packet, remove the LLC header
        if (macHeader.IsData()) {
            LlcSnapHeader llcHeader;
            snifferPacket->RemoveHeader(llcHeader);
        }

        // Extract the IPv4 header from the packet
        Ipv4Header ipv4Header;
        if (snifferPacket->PeekHeader(ipv4Header)) {

            Ipv4Address snifferIp = snifferNode->GetObject<Ipv4>()->GetAddress(1, 0).GetLocal();
            Ipv4Address senderIp = ipv4Header.GetSource();
            Ipv4Address receiverIp = ipv4Header.GetDestination();

            // If the sniffer IP is the same as the sender or receiver, or the message is a broadcast, skip processing
            if (senderIp == snifferIp || receiverIp == snifferIp || receiverIp == Ipv4Address("255.255.255.255")) {
                return;
            }

            // Extract the tag from the packet
            MyTag originalTag;
            if (snifferPacket->PeekPacketTag(originalTag)) {
              
                double timeNow = Simulator::Now().GetSeconds();
                Vector senderPosition = originalTag.GetPosition();
                int msgTag = originalTag.GetSimpleValue();
                double messageTime = originalTag.GetMessageTime();
                
                // Message content based on the message tag
                string messageContent;
                switch (msgTag) {
                    case 0: messageContent = "Search neighbors (Hello message)"; break;
                    case 1: messageContent = "Identification (Location message)"; break;
                    case 2: messageContent = "Update location (Trap message)"; break;
                    case 3: messageContent = "Special identification (Location message to neighbors beyond 1 hop and up to 80 meters away)"; break;
                    case 4: messageContent = "Suspect neighbor (FDI)"; break;
                    case 5: messageContent = "Blocked node"; break;
                    case 6: messageContent = "Suspicious reduction"; break;
                    default: messageContent = "Unknown"; break;
                }

                // Get information about neighbors from the tag
                vector<MyTag::NeighInfos> receivedNeighInfoList = originalTag.GetNeighInfosVector();
                vector<ns3::MyTag::NeighborFull> neighborListForStats;
                for (const auto& info : receivedNeighInfoList) {
                    MyTag::NeighborFull full_info;
                    full_info.ip = info.ip;
                    full_info.position.x = info.x;
                    full_info.position.y = info.y;
                    full_info.position.z = info.z;
                    full_info.hop = info.hop;
                    full_info.state = info.state;
                    full_info.distance = 0;
                    full_info.attitude = 0;
                    full_info.quality = 0;
                    
                    neighborListForStats.push_back(full_info);
                }

                // Print the captured information
                cout << snifferIp << " : " << timeNow << " Sniffer - Message " << msgTag << " : " << messageContent << " captured from " << senderIp 
                    << " at (" << senderPosition.x << ", " << senderPosition.y << ", " << senderPosition.z << ") to " << receiverIp;

                if (!neighborListForStats.empty())
                {
                    cout << " - The neighbors of " << senderIp << " are: " << neighborListForStats.size() << endl;
                    for (const auto& neighbor : neighborListForStats)
                    {
                        cout << neighbor.ip << " : Position x: " << neighbor.position.x << " y: " << neighbor.position.y 
                            << " z: " << neighbor.position.z << " hop: " << (int)neighbor.hop << endl;
                    }
                }
                else
                {
                    cout << endl;
                }
                cout << endl;

                // Call the statistics callback with the extracted information
                stats->SnifferCallback("", timeNow, senderPosition, snifferIp, senderIp, receiverIp, 
                                      msgTag, messageContent, neighborListForStats, messageTime);

                // Checks if sender and receiver are in the sniffer's coverage area
                if (snifferNode->IsAlreadyNeighbor(senderIp) && snifferNode->IsAlreadyNeighbor(receiverIp))
                {
                    ExecuteMiMAttack(snifferNode, packet, 
                                    snifferIp, senderIp, receiverIp, 
                                    originalTag, senderPosition);
                }
            } 
        }        
    }
}

/**
 * @brief Plot a 2D file
 * 
 */
void Create2DPlotFile ()
{
  std::string fileNameWithNoExtension = "plot-2d";
  std::string graphicsFileName        = fileNameWithNoExtension + ".png";
  std::string plotFileName            = fileNameWithNoExtension + ".plt";
  std::string plotTitle               = "2-D Plot";
  std::string dataTitle               = "2-D Data";

  // Instantiate the plot and set its title.
  Gnuplot plot (graphicsFileName);
  plot.SetTitle (plotTitle);

  // Make the graphics file, which the plot file will create when it
  // is used with Gnuplot, be a PNG file.
  plot.SetTerminal ("png");

  // Set the labels for each axis.
  plot.SetLegend ("X Values", "Y Values");

  // Set the range for the x axis.
  plot.AppendExtra ("set xrange [-6:+6]");

  // Instantiate the dataset, set its title, and make the points be
  // plotted along with connecting lines.
  Gnuplot2dDataset dataset;
  dataset.SetTitle (dataTitle);
  dataset.SetStyle (Gnuplot2dDataset::LINES_POINTS);

  double x;
  double y;

  // Create the 2-D dataset.
  for (x = -5.0; x <= +5.0; x += 1.0)
    {
      // Calculate the 2-D curve
      // 
      //            2
      //     y  =  x   .
      //  
      y = x * x;

      // Add this point.
      dataset.Add (x, y);
    }

  // Add the dataset to the plot.
  plot.AddDataset (dataset);

  // Open the plot file.
  std::ofstream plotFile (plotFileName.c_str());

  // Write the plot file.
  plot.GenerateOutput (plotFile);

  // Close the plot file.
  plotFile.close ();
}
} // namespace ns3