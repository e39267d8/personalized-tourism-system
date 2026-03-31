#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试数据生成脚本
用于生成符合要求的景点、设施、图结构测试数据

使用方法:
    python3 generate_test_data.py --nodes 200 --edges 500
"""

import argparse
import random
import json
from datetime import datetime, timedelta

# 配置
CITIES = ['北京市', '上海市', '广州市', '成都市', '杭州市']
SCENIC_CATEGORIES = [
    '自然景观', '人文景观', '主题乐园', '博物馆',
    '山水风光', '海滨海岛', '森林草原', '历史古迹', '宗教建筑'
]
FACILITY_TYPES = [
    '餐厅', '咖啡厅', '酒店', '地铁站', '公交站',
    '卫生间', '停车场', '医院', '警察局', '购物中心'
]
TRANSPORT_MODES = ['walk', 'bike', 'car', 'bus', 'subway']


def generate_random_coord(center_lat=39.9, center_lon=116.4, radius=0.5):
    """生成随机坐标（默认北京附近）"""
    lat = center_lat + random.uniform(-radius, radius)
    lon = center_lon + random.uniform(-radius, radius)
    return round(lon, 6), round(lat, 6)


def generate_scenic_spots(count=50):
    """生成景点数据"""
    spots = []
    for i in range(count):
        lon, lat = generate_random_coord()
        spot = {
            'id': i + 1,
            'name': f'景点_{i+1}',
            'description': f'这是第{i+1}个测试景点',
            'category_id': random.randint(1, 10),
            'longitude': lon,
            'latitude': lat,
            'address': f'{random.choice(CITIES)}测试区{i+1}号',
            'city': random.choice(CITIES),
            'ticket_price': round(random.uniform(0, 200), 2),
            'duration_hours': random.randint(60, 300),
            'crowd_level': random.randint(1, 4),
            'rating': round(random.uniform(3.5, 5.0), 2),
            'review_count': random.randint(10, 1000),
            'visit_count': random.randint(100, 10000),
            'status': 1,
            'tags': [random.choice(['历史', '文化', '自然', '现代']) for _ in range(random.randint(1, 3))]
        }
        spots.append(spot)
    return spots


def generate_facilities(count=50):
    """生成服务设施数据"""
    facilities = []
    for i in range(count):
        lon, lat = generate_random_coord()
        facility = {
            'id': i + 1,
            'name': f'{random.choice(FACILITY_TYPES)}_{i+1}',
            'facility_type_id': random.randint(1, 12),
            'longitude': lon,
            'latitude': lat,
            'address': f'{random.choice(CITIES)}设施区{i+1}号',
            'rating': round(random.uniform(3.0, 5.0), 2),
            'price_level': random.randint(1, 4),
            'status': 1
        }
        facilities.append(facility)
    return facilities


def generate_graph_nodes(scenic_spots, facilities, count=200):
    """生成图节点"""
    nodes = []
    
    # 添加景点作为节点
    for spot in scenic_spots:
        node = {
            'id': spot['id'],
            'node_type': 'scenic',
            'name': spot['name'],
            'longitude': spot['longitude'],
            'latitude': spot['latitude'],
            'scenic_spot_id': spot['id']
        }
        nodes.append(node)
    
    # 添加设施作为节点
    for fac in facilities:
        node = {
            'id': 1000 + fac['id'],
            'node_type': 'facility',
            'name': fac['name'],
            'longitude': fac['longitude'],
            'latitude': fac['latitude'],
            'facility_id': fac['id']
        }
        nodes.append(node)
    
    # 添加普通路口节点
    existing_count = len(nodes)
    for i in range(count - existing_count):
        lon, lat = generate_random_coord()
        node = {
            'id': 2000 + i,
            'node_type': 'junction',
            'name': f'路口_{i}',
            'longitude': lon,
            'latitude': lat
        }
        nodes.append(node)
    
    return nodes


def calculate_distance(lon1, lat1, lon2, lat2):
    """简化距离计算（实际应使用 Haversine 公式）"""
    import math
    R = 6371000  # 地球半径（米）
    
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    
    a = math.sin(delta_phi/2)**2 + \
        math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    return R * c


def generate_graph_edges(nodes, count=500):
    """生成图边"""
    edges = []
    edge_set = set()
    
    # 为每个节点生成随机边
    attempts = 0
    while len(edges) < count and attempts < count * 10:
        attempts += 1
        
        # 随机选择两个节点
        node1 = random.choice(nodes)
        node2 = random.choice(nodes)
        
        if node1['id'] == node2['id']:
            continue
        
        # 随机选择交通方式
        transport = random.choice(TRANSPORT_MODES)
        
        # 检查边是否已存在
        edge_key = (node1['id'], node2['id'], transport)
        if edge_key in edge_set:
            continue
        
        # 计算距离和耗时
        distance = calculate_distance(
            node1['longitude'], node1['latitude'],
            node2['longitude'], node2['latitude']
        )
        
        # 根据交通方式计算耗时
        speed_factors = {
            'walk': 1.4,    # m/s
            'bike': 5.0,
            'car': 15.0,
            'bus': 10.0,
            'subway': 20.0
        }
        duration = int(distance / speed_factors[transport])
        
        # 权重（基于时间和距离）
        weight = distance * 0.001 + duration * 0.1
        
        edge = {
            'from_node_id': node1['id'],
            'to_node_id': node2['id'],
            'transport_type': transport,
            'distance_meters': int(distance),
            'duration_seconds': duration,
            'base_weight': round(weight, 4),
            'dynamic_weight': round(weight, 4)
        }
        
        edges.append(edge)
        edge_set.add(edge_key)
    
    return edges


def generate_users(count=10):
    """生成用户数据"""
    users = []
    for i in range(count):
        user = {
            'username': f'user_{i+1}',
            'email': f'user{i+1}@example.com',
            'password_hash': 'hashed_password_placeholder',
            'nickname': f'用户{i+1}',
            'gender': random.randint(0, 2),
            'status': 1
        }
        users.append(user)
    return users


def generate_diaries(count=20):
    """生成游记数据"""
    diaries = []
    for i in range(count):
        start_date = datetime.now() - timedelta(days=random.randint(1, 365))
        end_date = start_date + timedelta(days=random.randint(1, 7))
        
        diary = {
            'user_id': random.randint(1, 10),
            'title': f'我的旅行日记_{i+1}',
            'content': f'这是一篇测试游记，内容省略...',
            'start_date': start_date.strftime('%Y-%m-%d'),
            'end_date': end_date.strftime('%Y-%m-%d'),
            'visibility': 1,
            'like_count': random.randint(0, 100),
            'view_count': random.randint(10, 1000),
            'mood': random.randint(1, 5)
        }
        diaries.append(diary)
    return diaries


def generate_reviews(count=50):
    """生成评论数据"""
    reviews = []
    for i in range(count):
        review = {
            'user_id': random.randint(1, 10),
            'target_type': random.choice(['scenic', 'facility']),
            'target_id': random.randint(1, 50),
            'rating': random.randint(1, 5),
            'title': f'评价_{i+1}',
            'content': '这是一条测试评论',
            'status': 1
        }
        reviews.append(review)
    return reviews


def save_to_sql(data, filename):
    """保存为 SQL 插入语句"""
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(f"-- 测试数据生成时间：{datetime.now()}\n\n")
        
        # 用户
        f.write("-- 用户数据\n")
        for user in data['users']:
            f.write(f"INSERT INTO users (username, email, password_hash, nickname, gender, status) ")
            f.write(f"VALUES ('{user['username']}', '{user['email']}', '{user['password_hash']}', ")
            f.write(f"'{user['nickname']}', {user['gender']}, {user['status']});\n")
        
        # 景点
        f.write("\n-- 景点数据\n")
        for spot in data['scenic_spots']:
            f.write(f"INSERT INTO scenic_spots ")
            f.write(f"(name, description, category_id, location, address, city, ")
            f.write(f"ticket_price, duration_hours, crowd_level, rating, review_count, ")
            f.write(f"visit_count, status, tags) VALUES (")
            f.write(f"'{spot['name']}', '{spot['description']}', {spot['category_id']}, ")
            f.write(f"ST_SetSRID(ST_MakePoint({spot['longitude']}, {spot['latitude']}), 4326), ")
            f.write(f"'{spot['address']}', '{spot['city']}, {spot['ticket_price']}, ")
            f.write(f"{spot['duration_hours']}, {spot['crowd_level']}, {spot['rating']}, ")
            f.write(f"{spot['review_count']}, {spot['visit_count']}, {spot['status']}, ")
            f.write(f"ARRAY[{','.join(map(lambda x: f\"'{x}'\", spot['tags']))}]);\n")
        
        # 设施
        f.write("\n-- 服务设施\n")
        for fac in data['facilities']:
            f.write(f"INSERT INTO facilities ")
            f.write(f"(name, facility_type_id, location, address, rating, price_level, status) VALUES (")
            f.write(f"'{fac['name']}', {fac['facility_type_id']}, ")
            f.write(f"ST_SetSRID(ST_MakePoint({fac['longitude']}, {fac['latitude']}), 4326), ")
            f.write(f"'{fac['address']}', {fac['rating']}, {fac['price_level']}, {fac['status']});\n")
        
        # 图节点
        f.write("\n-- 图节点\n")
        for node in data['nodes']:
            scenic_id = node.get('scenic_spot_id', 'NULL')
            facility_id = node.get('facility_id', 'NULL')
            if scenic_id:
                scenic_id_str = str(scenic_id)
            else:
                scenic_id_str = 'NULL'
            if facility_id:
                facility_id_str = str(facility_id)
            else:
                facility_id_str = 'NULL'
            
            f.write(f"INSERT INTO graph_nodes ")
            f.write(f"(node_type, name, location, scenic_spot_id, facility_id, properties) VALUES (")
            f.write(f"'{node['node_type']}', '{node['name']}, ")
            f.write(f"ST_SetSRID(ST_MakePoint({node['longitude']}, {node['latitude']}), 4326), ")
            f.write(f"{scenic_id_str}, {facility_id_str}, '{{}}');\n")
        
        # 图边
        f.write("\n-- 图边\n")
        for edge in data['edges']:
            f.write(f"INSERT INTO graph_edges ")
            f.write(f"(from_node_id, to_node_id, transport_type, distance_meters, ")
            f.write(f"duration_seconds, base_weight, dynamic_weight) VALUES (")
            f.write(f"{edge['from_node_id']}, {edge['to_node_id']}, '{edge['transport_type']}', ")
            f.write(f"{edge['distance_meters']}, {edge['duration_seconds']}, ")
            f.write(f"{edge['base_weight']}, {edge['dynamic_weight']});\n")
        
        # 游记
        f.write("\n-- 游记数据\n")
        for diary in data['diaries']:
            f.write(f"INSERT INTO travel_diaries ")
            f.write(f"(user_id, title, content, start_date, end_date, visibility, ")
            f.write(f"like_count, view_count, mood) VALUES (")
            f.write(f"{diary['user_id']}, '{diary['title']}, '{diary['content']}, ")
            f.write(f"'{diary['start_date']}', '{diary['end_date']}', {diary['visibility']}, ")
            f.write(f"{diary['like_count']}, {diary['view_count']}, {diary['mood']});\n")
        
        # 评论
        f.write("\n-- 评论数据\n")
        for review in data['reviews']:
            f.write(f"INSERT INTO reviews ")
            f.write(f"(user_id, target_type, target_id, rating, title, content, status) VALUES (")
            f.write(f"{review['user_id']}, '{review['target_type']}', {review['target_id']}, ")
            f.write(f"{review['rating']}, '{review['title']}, '{review['content']}, {review['status']});\n")


def main():
    parser = argparse.ArgumentParser(description='生成测试数据')
    parser.add_argument('--nodes', type=int, default=200, help='图节点数量')
    parser.add_argument('--edges', type=int, default=500, help='图边数量')
    parser.add_argument('--scenic', type=int, default=50, help='景点数量')
    parser.add_argument('--facilities', type=int, default=50, help='设施数量')
    parser.add_argument('--output', type=str, default='seed_data.sql', help='输出文件名')
    
    args = parser.parse_args()
    
    print(f"开始生成测试数据...")
    print(f"  - 节点数量：{args.nodes}")
    print(f"  - 边数量：{args.edges}")
    print(f"  - 景点数量：{args.scenic}")
    print(f"  - 设施数量：{args.facilities}")
    
    # 生成数据
    scenic_spots = generate_scenic_spots(args.scenic)
    facilities = generate_facilities(args.facilities)
    nodes = generate_graph_nodes(scenic_spots, facilities, args.nodes)
    edges = generate_graph_edges(nodes, args.edges)
    users = generate_users()
    diaries = generate_diaries()
    reviews = generate_reviews()
    
    # 组装数据
    data = {
        'users': users,
        'scenic_spots': scenic_spots,
        'facilities': facilities,
        'nodes': nodes,
        'edges': edges,
        'diaries': diaries,
        'reviews': reviews
    }
    
    # 保存到文件
    save_to_sql(data, args.output)
    
    print(f"\n✅ 测试数据已生成：{args.output}")
    print(f"   - 用户：{len(users)}")
    print(f"   - 景点：{len(scenic_spots)}")
    print(f"   - 设施：{len(facilities)}")
    print(f"   - 图节点：{len(nodes)}")
    print(f"   - 图边：{len(edges)}")
    print(f"   - 游记：{len(diaries)}")
    print(f"   - 评论：{len(reviews)}")


if __name__ == '__main__':
    main()
