char aux[200]; 
packetXBee* paq_sent;
uint8_t direction[8]={0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0xFF};

void setup()
{
  ACC.ON();
  xbee802.init(XBEE_802_15_4,FREQ2_4G,NORMAL);
  xbee802.ON();
}

void loop()
{
  paq_sent=(packetXBee*) calloc(1,sizeof(packetXBee)); 
  paq_sent->mode=BROADCAST; 
  paq_sent->MY_known=0; 
  paq_sent->packetID=0x52; 
  paq_sent->opt=0; 
  xbee802.hops=0; 
  xbee802.setOriginParams(paq_sent,MAC_TYPE);
  
  sprintf(aux,"|%d|%d|%d|%c",ACC.getX(),ACC.getY(),ACC.getZ(),'\n');

  xbee802.setDestinationParams(paq_sent, direction, aux, MAC_TYPE, DATA_ABSOLUTE);
  xbee802.sendXBee(paq_sent); 
  free(paq_sent);
  paq_sent = NULL;
  
}
