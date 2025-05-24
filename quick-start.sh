#!/bin/bash
# PT XYZ Data Warehouse - Simple Startup Script
# For Non-Technical Users

# Colors for better visibility
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏭 PT XYZ Data Warehouse - Easy Startup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if we're in the right directory
if [[ ! -f "config/docker/docker-compose.yml" ]]; then
    echo -e "${RED}❌ Error: Please run this script from the project directory${NC}"
    echo -e "${YELLOW}💡 Navigate to: /home/egistr/Documents/kuliah/semester6/dw/DW_Project_Kelompok22${NC}"
    exit 1
fi

echo -e "${YELLOW}🔄 Starting PT XYZ Data Warehouse...${NC}"
echo "This will take 2-3 minutes. Please wait..."
echo ""

# Start Docker services
echo -e "${BLUE}📦 Starting Docker services...${NC}"
if docker compose -f config/docker/docker-compose.yml up -d; then
    echo -e "${GREEN}✅ Docker services started successfully${NC}"
else
    echo -e "${RED}❌ Failed to start Docker services${NC}"
    echo -e "${YELLOW}💡 Try: sudo docker compose -f config/docker/docker-compose.yml up -d${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}⏳ Waiting for services to initialize...${NC}"
sleep 60

echo ""
echo -e "${GREEN}🎉 PT XYZ Data Warehouse is Ready!${NC}"
echo ""
echo -e "${BLUE}📊 Access Your Dashboards:${NC}"
echo -e "  • ${GREEN}Operations Dashboard:${NC} http://localhost:3000 (admin/admin)"
echo -e "  • ${GREEN}Business Analytics:${NC}   http://localhost:8088 (admin/admin)"
echo -e "  • ${GREEN}Business Reports:${NC}     http://localhost:3001"
echo -e "  • ${GREEN}Data Science:${NC}         http://localhost:8888 (token: ptxyz123)"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo -e "  • ${GREEN}User Guide:${NC} docs/USER_GUIDE.md"
echo -e "  • ${GREEN}Quick Help:${NC} ./bin/status-new.sh"
echo ""
echo -e "${YELLOW}💡 To stop the system: ./bin/stop.sh${NC}"
echo ""
echo -e "${GREEN}Happy analyzing! 🎯${NC}"
