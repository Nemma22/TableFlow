-- =========================================================================
-- TableFlow Seed Data
-- Sample menu items for development and testing.
-- Run embed_worker.py after inserting to generate vector embeddings.
-- =========================================================================

INSERT INTO menu (nombre_plato, descripcion, precio, tiempo_preparacion, clasificacion, content, metadata, embedding)
VALUES
(
    'Milanesa Napolitana',
    'Milanesa de ternera con salsa de tomate, jamón y queso gratinado. Servida con papas fritas.',
    '8500',
    '25m',
    'plato principal > carnes > ternera > gratinado',
    'Milanesa Napolitana: Milanesa de ternera con salsa de tomate, jamón y queso gratinado. Servida con papas fritas. Precio: $8500. Preparación: 25 minutos.',
    '{"nombre_plato": "Milanesa Napolitana", "descripcion": "Milanesa de ternera con salsa de tomate, jamón y queso gratinado", "precio": "8500", "tiempo_preparacion": "25m", "clasificacion": "plato principal > carnes > ternera > gratinado"}'::jsonb,
    NULL
),
(
    'Ensalada Caesar',
    'Lechuga romana, croutones, parmesano y aderezo Caesar casero con pollo grillado.',
    '6200',
    '15m',
    'entrada > ensalada > pollo > fresca',
    'Ensalada Caesar: Lechuga romana, croutones, parmesano y aderezo Caesar casero con pollo grillado. Precio: $6200. Preparación: 15 minutos.',
    '{"nombre_plato": "Ensalada Caesar", "descripcion": "Lechuga romana, croutones, parmesano y aderezo Caesar casero con pollo grillado", "precio": "6200", "tiempo_preparacion": "15m", "clasificacion": "entrada > ensalada > pollo > fresca"}'::jsonb,
    NULL
),
(
    'Tiramisú',
    'Postre italiano clásico con mascarpone, café espresso, cacao y vainillas.',
    '5800',
    '10m',
    'postre > italiano > café > frío',
    'Tiramisú: Postre italiano clásico con mascarpone, café espresso, cacao y vainillas. Precio: $5800. Preparación: 10 minutos.',
    '{"nombre_plato": "Tiramisú", "descripcion": "Postre italiano clásico con mascarpone, café espresso, cacao y vainillas", "precio": "5800", "tiempo_preparacion": "10m", "clasificacion": "postre > italiano > café > frío"}'::jsonb,
    NULL
)
ON CONFLICT (nombre_plato) DO NOTHING;
