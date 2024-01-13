#include <fstream>
#include <map>
#include <vector>

#include <algorithm>
#include <sstream>
#include <cstring>
#include <stdexcept>

#include "PublicHeader/Public.h"


using namespace std;
#include <algorithm>
struct WADHeader {
    char identification[4];
    int num_lumps;
    int info_table_offset;
} __attribute__((packed));

struct WADLump {
    int offset;
    int size;
    char name[8];
} __attribute__((packed));

struct WADLevel {
    WADLump head;
    vector<WADLump> data;
};

struct WADLineDef {
    unsigned short start_vertex;
    unsigned short end_vertex;
    unsigned short flags;
    unsigned short line_type;
    unsigned short sector_tag;
    unsigned short right_sidedef;
    unsigned short left_sidedef;
} __attribute__((packed));

struct WADSideDef {
    short offset_x;
    short offset_y;
    char upper_texture[8];
    char lower_texture[8];
    char middle_texture[8];
    short sector;
} __attribute__((packed));

struct WADVertex {
    short x;
    short y;
} __attribute__((packed));

struct WADSector {
    short floor_height;
    short ceiling_height;
    char floor_texture[8];
    char ceiling_texture[8];
    short light_level;
    short type;
    unsigned short tag;
} __attribute__((packed));

struct TextureAtlasInfo {
    int index;
    Vector2d_c size;
};

struct WADLevelData {
    vector<WADSector> sector;
    vector<WADVertex> vertex;
    vector<WADSideDef> side;
    vector<WADLineDef> line;
    map<string, TextureAtlasInfo> uvs;
};

struct WADPatches {
    int16_t m_origin_x;
    int16_t m_origin_y;
    uint16_t m_patch_id;
    uint16_t m_step_dir;
    uint16_t m_colormap;
} __attribute__((packed));

struct WADTexture12 {
    char m_name[8];
    uint32_t m_masked;
    uint16_t m_width;
    uint16_t m_height;
    uint32_t m_column_directory;
    uint16_t m_num_patches;
    vector<WADPatches> m_patches;
} __attribute__((packed));

struct WADPatchData
{
    int16_t width;
    int16_t height;
    int16_t left_offset;
    int16_t top_offset;
    vector<uint8_t> data;
} __attribute__((packed));

struct WADTextureHead {
    WADLump lump;
    int32_t offset;
} __attribute__((packed));

struct LumpNameComparator {
    const char* targetName;
    int length;

    LumpNameComparator(const char* name) : targetName(name) {
        length = strlen(targetName) < 8 ? (int)strlen(targetName) : 8;
    }

    bool operator()(const WADLump& lump) const {
        return strncmp(lump.name, targetName, length) == 0;
    }
};

#define Int16toFloat(x) (((float)x));

class WADLevelToPolygonConverter {
    Poligon ExportWallMesh(
        WADLevelData level,
        int floorHeight,
        int ceilingHeight,
        const char* textureName,
        int offsetX,
        int offsetY,
        const WADVertex *vertices,
        const WADLineDef &lineDef,
        char right,
        WADVertex center
    )
    {
        string key = string(textureName, strlen(textureName) < 8 ? strlen(textureName) : 8);
        auto baseUV = level.uvs.find(key);
//        if (baseUV == level.uvs.end() && key[0] != 0 && key[0] != '-') {
//            throw runtime_error("UV not found: " + string(key));
//        }
        WADVertex startVertex = vertices[lineDef.start_vertex];
        WADVertex endVertex = vertices[lineDef.end_vertex];
//        if (right) {
//            WADVertex tmp = startVertex;
//            startVertex = endVertex;
//            endVertex = tmp;
//        }
        startVertex.x -= center.x;
        endVertex.x -= center.x;
        startVertex.y -= center.y;
        endVertex.y -= center.y;

        int height = ceilingHeight - floorHeight;
        int dx = (startVertex.x - endVertex.x);
        int dy = (startVertex.y - endVertex.y);
        int width = sqrt(dx * dx + dy * dy);

        float offsetU = ((float)(offsetX)) / baseUV->second.size.x;
        float offsetV = ((float)(offsetY)) / baseUV->second.size.y;

        float endU = ((float)(width + offsetX)) / baseUV->second.size.x;
        float endV = ((float)(height + offsetY)) / baseUV->second.size.y;

        Poligon result;
        result.atlas = baseUV->second.index;

        //    manualMesh.position(-startVertex.iX, floorHeight, startVertex.iY);
        //    manualMesh.textureCoord(offsetU, endV);
        result.p1.x = Int16toFloat(-startVertex.x);
        result.p1.y = Int16toFloat(floorHeight);
        result.p1.z = Int16toFloat(startVertex.y);
        result.uv1.x = offsetU;
        result.uv1.y = endV;

        //    manualMesh.position(-startVertex.iX, ceilingHeight, startVertex.iY);
        //    manualMesh.textureCoord(offsetU, offsetV);

        result.p2.x = Int16toFloat(-startVertex.x);
        result.p2.y = Int16toFloat(ceilingHeight);
        result.p2.z = Int16toFloat(startVertex.y);
        result.uv2.x = offsetU;
        result.uv2.y = offsetV;

        //    manualMesh.position(-endVertex.iX, ceilingHeight, endVertex.iY);
        //    manualMesh.textureCoord(endU, offsetV);
        result.p3.x = Int16toFloat(-endVertex.x);
        result.p3.y = Int16toFloat(ceilingHeight);
        result.p3.z = Int16toFloat(endVertex.y);
        result.uv3.x = endU;
        result.uv3.y = offsetV;

        //    manualMesh.position(-endVertex.iX, floorHeight, endVertex.iY);
        //    manualMesh.textureCoord(endU, endV);
        result.p4.x = Int16toFloat(-endVertex.x);
        result.p4.y = Int16toFloat(floorHeight);
        result.p4.z = Int16toFloat(endVertex.y);
        result.uv4.x = endU;
        result.uv4.y = endV;

        result.right = right;

        return result;
    }

    void findMinMax(const std::vector<WADVertex>& vertices, short& minX, short& maxX, short& minY, short& maxY) {
        // Инициализация минимальных и максимальных значений
        minX = std::numeric_limits<short>::max();
        maxX = std::numeric_limits<short>::min();
        minY = std::numeric_limits<short>::max();
        maxY = std::numeric_limits<short>::min();

        // Проход по всем вершинам
        for (const auto& vertex : vertices) {
            // Обновление минимальных и максимальных значений x
            if (vertex.x < minX) {
                minX = vertex.x;
            }
            if (vertex.x > maxX) {
                maxX = vertex.x;
            }

            // Обновление минимальных и максимальных значений y
            if (vertex.y < minY) {
                minY = vertex.y;
            }
            if (vertex.y > maxY) {
                maxY = vertex.y;
            }
        }
    }

public:
    void wallMesh(std::vector<Poligon>& result, const WADLevelData &level, const WADVertex *vertices, const WADLineDef &lineDef, WADVertex center) {

        auto left = level.side[lineDef.left_sidedef];
        auto right = level.side[lineDef.right_sidedef];

        const WADSector &rSideSector = level.sector[right.sector];
        const WADSector &lSideSector = level.sector[left.sector];

        if (left.middle_texture[0] != 0 && left.middle_texture[0] != '-') {
            result.push_back(ExportWallMesh(level, lSideSector.floor_height, lSideSector.ceiling_height, left.middle_texture, left.offset_x, left.offset_y, vertices, lineDef, 1, center));
        } else if (left.lower_texture[0] != 0 && left.lower_texture[0] != '-') {
            result.push_back(ExportWallMesh(level, lSideSector.floor_height, rSideSector.ceiling_height, left.lower_texture, left.offset_x, left.offset_y, vertices, lineDef, 1, center));
        } else if (left.upper_texture[0] != 0 && left.upper_texture[0] != '-') {
            result.push_back(ExportWallMesh(level, rSideSector.floor_height, lSideSector.ceiling_height, left.upper_texture, left.offset_x, left.offset_y, vertices, lineDef, 1, center));
        }

        if (right.middle_texture[0] != 0 && right.middle_texture[0] != '-') {
            result.push_back(ExportWallMesh(level, rSideSector.floor_height, rSideSector.ceiling_height, right.middle_texture, right.offset_x, right.offset_y, vertices, lineDef, 0, center));
        } else if (right.lower_texture[0] != 0 && right.lower_texture[0] != '-') {
            result.push_back(ExportWallMesh(level, rSideSector.floor_height, lSideSector.ceiling_height, right.lower_texture, right.offset_x, right.offset_y, vertices, lineDef, 0, center));
        } else if (right.upper_texture[0] != 0 && right.upper_texture[0] != '-') {
            result.push_back(ExportWallMesh(level, lSideSector.floor_height, rSideSector.ceiling_height, right.upper_texture, right.offset_x, right.offset_y, vertices, lineDef, 0, center));
        }
    }

    PoligonInfo* ExportLevel(const WADLevelData &level)
    {
        std::vector<Poligon> result;
        const WADLineDef *lineDefs = level.line.data();
        const size_t numLineDefs = level.line.size();

        const WADSideDef *sideDefs = level.side.data();

        const WADVertex *vertices = level.vertex.data();

        short minX, maxX, minY, maxY;
        findMinMax(level.vertex, minX, maxX, minY, maxY);
        WADVertex center = WADVertex();
        center.x = (maxX + minX) / 2;
        center.y = (maxY + minY) / 2;

        float scale = max(maxX - minX, maxY - minY);

        for(size_t i = 0;i < numLineDefs; ++i)
        {
            wallMesh(result, level, vertices, lineDefs[i], center);
        }

        PoligonInfo* out = new PoligonInfo();
        out->polygons = new Poligon[result.size()];
        out->count = (unsigned int)result.size();
        memcpy(out->polygons, result.data(), result.size() * sizeof(Poligon));
        return out;
    }
};

class WADParser {
public:
    WADParser(const string& filename) {
        wad_file = new ifstream(filename, ios::binary);
        if (wad_file == NULL || !wad_file->is_open()) {
            throw runtime_error("Не удалось открыть файл");
        }
        parse();
    }

    WADLevelData loadLevel(const char* input) {
        char name[9];
        name[8] = 0;
        for (int j = 0; j < 8; j++) {
            name[j] = input[j];
        }
        string value = string(input, strlen(input));
        // Проверка наличия уровня с указанным именем
        auto levelIt = levels.find(value);
        if (levelIt == levels.end()) {
            throw runtime_error("Level not found: " + string(input));
        }

        WADLevelData levelData;

        // Загрузка данных для каждой модели
        levelData.sector = loadData<WADSector>(levelIt->second, "SECTORS");
        levelData.vertex = loadData<WADVertex>(levelIt->second, "VERTEXES");
        levelData.side = loadData<WADSideDef>(levelIt->second, "SIDEDEFS");
        levelData.line = loadData<WADLineDef>(levelIt->second, "LINEDEFS");
        levelData.uvs = uvs;

        return levelData;
    }

    ~WADParser() {
        if (wad_file == NULL) {
            wad_file->close();
            delete wad_file;
        }
    }

    vector<uint8_t> globalTexture;
    uint16_t globalTextureSize = 4096;
    map<string, TextureAtlasInfo> uvs;
    vector<Atlas> atlas;

private:
    ifstream* wad_file;
    WADHeader header;
    vector<WADLump> lumps;
    map<string, WADLevel> levels;
    vector<string> categories;
    map<string, WADTexture12> textures;
    vector<WADPatchData> patchData;
    vector<uint8_t> palette;

    WADVertex globalTexturePosition;
    int globalTextureHeight;


    void readHeader() {
        wad_file->read(reinterpret_cast<char*>(&header), sizeof(WADHeader));
    }

    void parse() {
        globalTextureHeight = 0;
        globalTexturePosition.x = 0;
        globalTexturePosition.y = 0;
        globalTexture.resize(globalTextureSize * globalTextureSize * 4);
        loadCategoryType();
        readHeader();
        readLumps();
        for (auto lump: lumps) { printf("%s\n", lump.name); }

        loadLevel();
        loadPatch();
    }

    void loadCategoryType() {
        categories.push_back("THINGS");
        categories.push_back("LINEDEFS");
        categories.push_back("SIDEDEFS");
        categories.push_back("VERTEXES");
        categories.push_back("SEGS");
        categories.push_back("SSECTORS");
        categories.push_back("NODES");
        categories.push_back("SECTORS");
        categories.push_back("REJECT");
        categories.push_back("BLOCKMAP");
    }

    void readLumps() {
        lumps.resize(header.num_lumps);
        wad_file->seekg(header.info_table_offset, ios::beg);
        wad_file->read(reinterpret_cast<char*>(lumps.data()), sizeof(WADLump) * header.num_lumps);
    }

    void loadLevel() {
        groupLumpsByLevel();
    }

    void groupLumpsByLevel() {
        WADLevel currentLevel;

        for (const auto& lump : lumps) {
            if (lump.size == 0) {
                currentLevel = WADLevel();
                currentLevel.head = lump;
            } else {
                const string lumpName(lump.name, (strlen(lump.name) < 8 ?  strlen(lump.name) : 8));
                if (isCategory(lumpName)) {
                    currentLevel.data.push_back(lump);
                    levels[string(currentLevel.head.name, (strlen(currentLevel.head.name) < 8 ?  strlen(currentLevel.head.name) : 8))] = currentLevel;
                }
            }
        }
    }

    bool isCategory(const string& lumpName) const {
        return find(categories.begin(), categories.end(), lumpName) != categories.end();
    }

    void loadPalette() {
        auto lump = this->searchLump("PLAYPAL");
        wad_file->seekg(lump.offset, ios::beg);
        palette.resize(lump.size);
        wad_file->read((char*)&palette[0], lump.size);
    }

    void loadPatch() {
        auto it = find_if(lumps.begin(), lumps.end(), LumpNameComparator("PNAMES"));

        if (it == lumps.end()) {
            throw runtime_error("Lump not found: " + string("PNAMES"));
        }

        wad_file->seekg(it->offset, ios::beg);

        uint32_t numTextures;
        wad_file->read(reinterpret_cast<char*>(&numTextures), sizeof(numTextures));

        char name[9];
        name[8] = 0;
        vector<WADLump> lumps;
        for (int i = 0; i<numTextures; i++) {
            wad_file->read(name, 8);
            auto sName = string(name, strlen(name) < 8 ? strlen(name) : 8);
            auto lump = this->searchLump(name);
            lumps.push_back(lump);
        }
        for (auto lump: lumps) {
            addNewPatch(lump);
        }
        loadPalette();
        loadAllTexture();
    }

    void addNewPatch(WADLump lump) {
        WADPatchData result = WADPatchData();
        wad_file->seekg(lump.offset, ios::beg);
        auto headSize = sizeof(WADPatchData) - sizeof(vector<uint8_t>);
        wad_file->read((char*)&result, headSize);
        result.data.resize(lump.size - headSize);
        wad_file->read((char*)&result.data[0], lump.size - headSize);
        patchData.push_back(result);
    }

    void loadAllTexture() {
        auto texture1 = find_if(lumps.begin(), lumps.end(), LumpNameComparator("TEXTURE1"));
        if (texture1 != lumps.end()) {
            loadTextures(*texture1);
        }

        auto texture2 = find_if(lumps.begin(), lumps.end(), LumpNameComparator("TEXTURE2"));
        if (texture2 != lumps.end()) {
            loadTextures(*texture2);
        }

        for (auto texture: textures) {
            loadTexture(texture.first, texture.second);
        }
    }

    void loadTexture(string name, WADTexture12 texture) {
        vector<uint8_t> output;
        output.resize(texture.m_width * texture.m_height * 3);
        std::size_t pixelCount = 0;
        for(int i = 0; i < texture.m_num_patches; ++i)
        {
            WADPatches path = texture.m_patches[i];
            WADPatchData data = this->patchData[path.m_patch_id];

            int x1 = path.m_origin_x;
            int x2 = x1 + data.width;

            int x = std::max(x1, 0);

            x2 = std::min(x2, static_cast<int>(texture.m_width));

            size_t patchTotal = 0;
            for(;x < x2; ++x)
            {
                uint32_t* offset = (uint32_t*)&data.data[0];
                uint headSize = (sizeof(WADPatchData) - sizeof(vector<uint8_t>));
                const uint8_t *patchPixels = &data.data[offset[(x - x1)] - headSize];
                //uint8_t *destColumn = texPixels + (x * textureInfo.uHeight);
                size_t destColumnOffset = 0;

                for(;;)
                {
                    uint8_t topDelta = *patchPixels;
                    if(topDelta == 0xff)
                        break;

                    if(topDelta > 0)
                    {
                        //destColumn = texPixels + (x * textureInfo.uHeight);
                        destColumnOffset = 0;
                    }

                    int patchLength = *(patchPixels+1);
                    int count = patchLength;

                    int position = path.m_origin_y + topDelta;
                    if(position < 0)
                    {
                        count += position;
                        position = 0;
                    }

                    if(position + count > texture.m_height)
                    {
                        count = texture.m_height - position;
                    }

                    if(count > 0)
                    {
                        const uint8_t *source = patchPixels + 3;

                        //memcpy(destColumn + position, source, count);
                        for(int pixelCounter = 0;pixelCounter < count; ++pixelCounter)
                        {
                            output[((destColumnOffset + pixelCounter + position) * texture.m_width) + x] = *(source + pixelCounter);
                        }
                        //destColumn += count;
                        destColumnOffset += count;
                    }

                    patchPixels += patchLength + 4;
                }
            }
        }
        if (globalTexturePosition.x + texture.m_width >= globalTextureSize) {
            globalTexturePosition.x = 0;
            globalTexturePosition.y = globalTextureHeight;
        }
        for (int x = 0; x < texture.m_width; x++) {
            for (int y = 0; y < texture.m_height; y++) {
                auto position = (globalTexturePosition.x + x + (globalTexturePosition.y + y) * globalTextureSize) * 4;
                auto pelettePos = (output[x + y * texture.m_width]) * 3;
                globalTexture[position + 2] = palette[pelettePos];
                globalTexture[position + 1] = palette[pelettePos + 1];
                globalTexture[position] = palette[pelettePos + 2];
                globalTexture[position + 3] = 255;
            }
        }
        int index = (int)atlas.size();
        auto item = Atlas();
        item.position.x = ((float)globalTexturePosition.x) / ((float)globalTextureSize);
        item.position.y = ((float)globalTexturePosition.y) / ((float)globalTextureSize);
        item.size.x = ((float)texture.m_width) / ((float)globalTextureSize);
        item.size.y = ((float)texture.m_height) / ((float)globalTextureSize);
        atlas.push_back(item);
        uvs[name] = TextureAtlasInfo();
        uvs[name].index = index;
        uvs[name].size.x = texture.m_width;
        uvs[name].size.y = texture.m_height;
        globalTexturePosition.x += texture.m_width;
        if (texture.m_height + globalTexturePosition.y > globalTextureHeight) {
            globalTextureHeight = texture.m_height + globalTexturePosition.y;
        }
    }

    WADLump searchLump(const char *name) {
        int i = 0;
        char upName[9];
        while (name[i] && i < 8) {
            upName[i] = toupper(name[i]);
            i++;
        }
        upName[strlen(name) < 8 ? strlen(name) : 8] = 0;
        auto it = find_if(lumps.begin(), lumps.end(), LumpNameComparator(upName));

        if (it == lumps.end()) {
            throw runtime_error("Lump not found: " + string(name));
        }
        return *it;
    }

    void loadTextures(const WADLump textureLump) {
        int textureLumpOffset = textureLump.offset;
        int textureLumpSize = textureLump.size;
        wad_file->seekg(textureLumpOffset, ios::beg);

        uint32_t numTextures;
        wad_file->read(reinterpret_cast<char*>(&numTextures), sizeof(numTextures));

        wad_file->seekg(numTextures * 4, std::ios_base::cur);

        for (uint32_t i = 0; i < numTextures; ++i) {
            WADTexture12 texture;
            wad_file->read(reinterpret_cast<char*>(&texture), sizeof(WADTexture12) - sizeof(vector<WADPatches>));
            texture.m_patches.resize(texture.m_num_patches);
            wad_file->read(reinterpret_cast<char*>(&texture.m_patches[0]), texture.m_num_patches * sizeof(WADPatches));
            textures[string(texture.m_name, strlen(texture.m_name) < 8 ? strlen(texture.m_name) : 8)] = texture;
        }
    }

    template<typename T>
    vector<T> loadData(const WADLevel& level, const char* targetName) {
        vector<T> data;

        auto it = find_if(level.data.begin(), level.data.end(), LumpNameComparator(targetName));

        if (it == level.data.end()) {
            throw runtime_error("Lump not found: " + string(targetName));
        }

        wad_file->seekg(it->offset, ios::beg);

        auto structSize = sizeof(T);
        if (it->size % structSize != 0) {
            throw runtime_error("Incorrect size");
        }

        for (int i = 0; i < it->size / structSize; ++i) {
            T item;
            wad_file->read(reinterpret_cast<char*>(&item), sizeof(T));
            data.push_back(item);
        }
        return data;
    }

    vector<WADLineDef> loadLineDefs(const WADLevel& level) {
        const char* targetName = "LINEDEFS";
        return loadData<WADLineDef>(level, targetName);
    }

    vector<WADSideDef> loadSideDefs(const WADLevel& level) {
        const char* targetName = "SIDEDEFS";
        return loadData<WADSideDef>(level, targetName);
    }

    vector<WADVertex> loadVertexes(const WADLevel& level) {
        const char* targetName = "VERTEXES";
        return loadData<WADVertex>(level, targetName);
    }

    vector<WADSector> loadSectors(const WADLevel& level) {
        const char* targetName = "SSECTORS";
        return loadData<WADSector>(level, targetName);
    }
};

PoligonInfo* loadPolygonsFromWadFile(const char* path, const char* levelName) {
    try {
        WADParser parser = WADParser(path);
        WADLevelData data = parser.loadLevel(levelName);
        PoligonInfo* result = WADLevelToPolygonConverter().ExportLevel(data);
        result->texture = new unsigned char[4 * parser.globalTextureSize * parser.globalTextureSize];
        result->textureSize = parser.globalTextureSize;
        memcpy(result->texture, parser.globalTexture.data(), 4 * parser.globalTextureSize * parser.globalTextureSize);

        result->atlasSize = (int)parser.atlas.size();
        result->atlas = new Atlas[parser.atlas.size()];
        memcpy(result->atlas, parser.atlas.data(), sizeof(Atlas) * parser.atlas.size());

        return result;
    }
    catch(std::exception &e) {
        return NULL;
    }
}

void deletePoligonInfo(struct PoligonInfo* info) {
    if (info != NULL) {
        delete info->atlas;
        delete info->texture;
        delete info->polygons;
        delete info;
    }
}
