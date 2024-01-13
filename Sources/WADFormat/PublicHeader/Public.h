#ifndef Header_h
#define Header_h

#ifdef __cplusplus
extern "C" {
#endif

struct Vector2d_c {
    float x, y;
};

struct Vector3d_c {
    float x, y, z;
};

struct Atlas {
    struct Vector2d_c position;
    struct Vector2d_c size;
};

struct Poligon {
    char right;
    unsigned short atlas;
    struct Vector3d_c p1, p2, p3, p4;
    struct Vector2d_c uv1, uv2, uv3, uv4;
};

struct PoligonInfo {
    unsigned int atlasSize;
    struct Atlas* atlas;
    unsigned char* texture;
    unsigned int textureSize;
    unsigned int count;
    struct Poligon* polygons;
};

struct PoligonInfo* loadPolygonsFromWadFile(const char* path, const char* levelName);
void deletePoligonInfo(struct PoligonInfo* info);

#ifdef __cplusplus
}
#endif

#endif /* Header_h */
