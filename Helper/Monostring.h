#pragma once

#include <map>

template <typename T>
struct monoArray
{
    void* klass;
    void* monitor;
    void* bounds;
    int   max_length;
    T vector [0];
    int getLength()
    {
        return max_length;
    }
    T *getPointer()
    {
        return vector;
    }

    template<typename V = T>
    std::vector<V> toCPPlist() {
        std::vector<V> ret;
        for (int i = 0; i < max_length; i++)
            ret.push_back(vector[i]);
        return std::move(ret);
    }
};

template <typename T>
struct monoList {
    void *unk0;
    void *unk1;
    monoArray<T> *items;
    int size;
    int version;

    T getItems(){
        return items->getPointer();
    }

    int getSize(){
        return size;
    }

    int getVersion(){
        return version;
    }
};

template<typename TKey, typename TValue>
    struct Dictionary {
    struct Entry {
        int hashCode, next;
        TKey key;
        TValue value;
    };
    void *klass;
    void *monitor;
    monoArray<int> *buckets;
    monoArray<Entry> *entries;
    int count;
    int version;
    int freeList;
    int freeCount;
    void *comparer;
    monoArray<TKey> *keys;
    monoArray<TValue> *values;
    void *syncRoot;

    std::map<TKey, TValue> toMap() {
        std::map<TKey, TValue> ret;
        auto lst = entries->template toCPPlist();
        for (auto enter : lst)
            ret.insert(std::make_pair(enter.key, enter.value));
        return std::move(ret);
    }

    std::vector<TKey> getKeys() {
        std::vector<TKey> ret;
        auto lst = entries->template toCPPlist();
        for (auto enter : lst)
            ret.push_back(enter.key);
        return std::move(ret);
    }

    std::vector<TValue> getValues() {
        std::vector<TValue> ret;
        auto lst = entries->template toCPPlist();
        for (auto enter : lst)
            ret.push_back(enter.value);
        return std::move(ret);
    }

    int getSize() {
        return count;
    }

    int getVersion() {
        return version;
    }

    bool TryGet(TKey key, TValue &value);
    void Add(TKey key, TValue value);
    void Insert(TKey key, TValue value);
    bool Remove(TKey key);
    bool ContainsKey(TKey key);
    bool ContainsValue(TValue value);

    TValue Get(TKey key) {
        TValue ret;
        if (TryGet(key, ret))
            return ret;
        return {};
    }

    TValue operator [](TKey key) {
        return Get(key);
    }
};

union intfloat {
    int i;
    float f;
};

typedef struct _monoString
{
    void* klass;
    void* monitor;
    int length;    
    char chars[1];   
    int getLength()
    {
      return length;
    }
    char* getChars()
    {
        return chars;
    }
    NSString* toNSString()
    {
      return [[NSString alloc] initWithBytes:(const void *)(chars)
                     length:(NSUInteger)(length * 2)
                     encoding:(NSStringEncoding)NSUTF16LittleEndianStringEncoding];
    }

    char* toCString()
    {
      NSString* v1 = toNSString();
      return (char*)([v1 UTF8String]);  
    }
    std::string toCPPString()
    {
      return std::string(toCString());
    }
}monoString;